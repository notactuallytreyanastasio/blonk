import express from 'express';
import session from 'express-session';
import expressLayouts from 'express-ejs-layouts';
import path from 'path';
import { BlonkAgent } from './agent';
import { BlipManager } from './blips';
import * as dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, '../views'));
app.use(expressLayouts);
app.set('layout', 'layout');
app.use(express.static(path.join(__dirname, '../public')));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.use(session({
  secret: process.env.SESSION_SECRET || 'blonk-secret-key',
  resave: false,
  saveUninitialized: true,
}));

let agent: BlonkAgent;
let blipManager: BlipManager;

async function initializeAgent() {
  agent = new BlonkAgent();
  await agent.login();
  blipManager = new BlipManager(agent.getAgent());
  console.log('✅ Connected to AT Protocol');
}

app.get('/', async (req, res) => {
  try {
    const blips = await blipManager.getBlips(50);
    res.render('index', { blips, user: req.session.user });
  } catch (error) {
    console.error('Error fetching blips:', error);
    res.render('index', { blips: [], user: req.session.user });
  }
});

app.get('/submit', (req, res) => {
  res.render('submit', { user: req.session.user });
});

app.post('/submit', async (req, res) => {
  try {
    const { title, url, body, tags } = req.body;
    const tagArray = tags ? tags.split(' ').filter((t: string) => t.length > 0) : [];
    
    await blipManager.createBlip(title, body, url, tagArray);
    res.redirect('/');
  } catch (error) {
    console.error('Error creating blip:', error);
    res.render('submit', { error: 'Failed to create blip', user: req.session.user });
  }
});

app.get('/tag/:tag', async (req, res) => {
  try {
    const allBlips = await blipManager.getBlips(100);
    const taggedBlips = allBlips.filter(blip => 
      blip.tags?.includes(req.params.tag)
    );
    res.render('tag', { blips: taggedBlips, tag: req.params.tag, user: req.session.user });
  } catch (error) {
    console.error('Error fetching tagged blips:', error);
    res.render('tag', { blips: [], tag: req.params.tag, user: req.session.user });
  }
});

initializeAgent().then(() => {
  app.listen(PORT, () => {
    console.log(`🌐 Blonk server running at http://localhost:${PORT}`);
  });
}).catch(error => {
  console.error('Failed to initialize:', error);
  process.exit(1);
});