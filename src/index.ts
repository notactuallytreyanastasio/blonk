import { BlonkAgent } from './agent';
import { PostManager } from './posts';

async function main() {
  try {
    const blonkAgent = new BlonkAgent();
    await blonkAgent.login();
    
    const agent = blonkAgent.getAgent();
    const postManager = new PostManager(agent);

    console.log('\n🚀 Blonk - AT Protocol Reddit Clone');
    console.log('=====================================\n');

    console.log('Creating a test post...');
    const postUri = await postManager.createPost(
      'Welcome to Blonk!',
      'This is the first post on Blonk, a Reddit clone built on AT Protocol.',
      'https://atproto.com'
    );
    console.log(`Post created with URI: ${postUri}\n`);

    console.log('Fetching recent posts...');
    const posts = await postManager.getPosts(10);
    
    console.log(`\nFound ${posts.length} posts:`);
    posts.forEach((post, index) => {
      console.log(`\n${index + 1}. ${post.title}`);
      if (post.body) console.log(`   ${post.body.substring(0, 100)}...`);
      if (post.url) console.log(`   🔗 ${post.url}`);
      console.log(`   📅 ${new Date(post.createdAt).toLocaleString()}`);
      console.log(`   ⬆️  ${post.votes} votes`);
    });

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();