# Seed script for "that_guy" vibe with Reddit-style content
import Ecto.Query
alias ElixirBlonk.{Repo, Vibes, Blips}
alias ElixirBlonk.Vibes.Vibe
alias ElixirBlonk.Blips.Blip

# First, create the "that_guy" vibe if it doesn't exist
that_guy_vibe = case Repo.get_by(Vibe, name: "that_guy") do
  nil ->
    {:ok, vibe} = Vibes.create_vibe(%{
      uri: "at://blonk.app/vibe/that_guy",
      cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
      creator_did: "did:plc:6e6n5nhhy7s2zqr7wx4s6p52",
      name: "that_guy",
      mood: "we all know that guy",
      emoji: "🙄",
      color: "#FF6B6B",
      member_count: 1,
      pulse_score: 7.5,
      is_emerging: false
    })
    vibe
  
  existing_vibe -> existing_vibe
end

# Reddit-style titles and content for "that_guy"
reddit_posts = [
  %{
    title: "AITA for calling out my coworker who always takes credit for team ideas?",
    body: "This guy literally waits until someone suggests something in meetings, then rephrases it and acts like it was his brilliant insight. Today I couldn't take it anymore...",
    url: "https://reddit.com/r/AmItheAsshole/comments/xyz123",
    tags: ["workplace", "credit_stealing", "meetings", "coworker", "drama"]
  },
  %{
    title: "Guy at the gym always leaves weights everywhere and grunts loudly",
    body: "You know the type. Loads up 315 on bench, does quarter reps, screams like he's giving birth, then walks away without reracking anything.",
    url: "https://reddit.com/r/gymstories/comments/abc456",
    tags: ["gym", "etiquette", "weights", "annoying", "loud"]
  },
  %{
    title: "Dude in my apartment building parks in two spots every single day",
    body: "His Honda Civic somehow needs the space of two parking spots. I've left notes, talked to management, nothing works. Peak that guy behavior.",
    url: "https://reddit.com/r/mildlyinfuriating/comments/def789",
    tags: ["parking", "apartment", "selfish", "inconsiderate", "notes"]
  },
  %{
    title: "Guy at Starbucks orders 10 drinks during rush hour with complicated modifications",
    body: "Half-caf oat milk macchiato with extra foam, no foam, 2 pumps vanilla, 1 pump caramel, 140 degrees exactly... while 20 people wait behind him.",
    url: "https://reddit.com/r/starbucks/comments/ghi012",
    tags: ["starbucks", "coffee", "complicated_orders", "rush_hour", "queue"]
  },
  %{
    title: "Roommate who never does dishes but complains when I use 'his' clean plates",
    body: "Hasn't touched a sponge in 6 months but gets territorial about the dishes I washed. Classic that guy move.",
    url: "https://reddit.com/r/badroommates/comments/jkl345",
    tags: ["roommate", "dishes", "cleaning", "territorial", "hypocrite"]
  },
  %{
    title: "Guy in my CS class who corrects the professor constantly",
    body: "Actually sir, that's not technically correct because in the 1987 specification... Dude, we're learning basic loops, chill.",
    url: "https://reddit.com/r/cscareerquestions/comments/mno678",
    tags: ["computer_science", "class", "professor", "corrections", "annoying"]
  },
  %{
    title: "Neighbor who mows his lawn at 6 AM every Saturday",
    body: "Without fail. 6:00 AM sharp. Saturdays are for sleeping in, not industrial landscaping at dawn.",
    url: "https://reddit.com/r/neighbors/comments/pqr901",
    tags: ["neighbor", "lawn", "early_morning", "saturday", "noise"]
  },
  %{
    title: "Guy who replies to every email with 'Reply All' even for personal responses",
    body: "Thanks for the birthday wishes! -> Reply All. Got it, see you at 2pm -> Reply All. The whole company knows his lunch preferences now.",
    url: "https://reddit.com/r/work/comments/stu234",
    tags: ["email", "reply_all", "work", "communication", "oversharing"]
  },
  %{
    title: "Dude at parties who brings a guitar and won't stop playing Wonderwall",
    body: "Every. Single. Party. The guitar appears, the circle forms, and we all suffer through his acoustic setlist of 2005 hits.",
    url: "https://reddit.com/r/party/comments/vwx567",
    tags: ["party", "guitar", "wonderwall", "acoustic", "attention_seeking"]
  },
  %{
    title: "Guy who takes phone calls on speaker in public places",
    body: "Grocery store, elevator, library - doesn't matter. His personal conversations are now everyone's entertainment.",
    url: "https://reddit.com/r/publicfreakout/comments/yza890",
    tags: ["phone_calls", "speaker", "public", "privacy", "inconsiderate"]
  },
  %{
    title: "Coworker who heats up fish in the office microwave daily",
    body: "The smell permeates three floors. HR has been contacted. This is biological warfare disguised as lunch.",
    url: "https://reddit.com/r/officelife/comments/bcd123",
    tags: ["office", "microwave", "fish", "smell", "workplace_etiquette"]
  },
  %{
    title: "Guy who mansplains things to experts in their own field",
    body: "Watched him explain coding to a senior software engineer, cooking to a chef, and car mechanics to... a mechanic. The audacity.",
    url: "https://reddit.com/r/mansplaining/comments/efg456",
    tags: ["mansplaining", "experts", "audacity", "condescending", "know_it_all"]
  },
  %{
    title: "Dude who cuts in line and acts like he was always there",
    body: "The gaslighting master. 'Oh I was just talking to my friend up there.' No sir, you were not.",
    url: "https://reddit.com/r/linecutters/comments/hij789",
    tags: ["line_cutting", "gaslighting", "queue", "dishonest", "social_rules"]
  },
  %{
    title: "Guy who never tips but always has money for expensive drinks",
    body: "Orders $15 cocktails all night, leaves zero tip. 'Service was fine, just don't believe in tipping culture.'",
    url: "https://reddit.com/r/talesfromyourserver/comments/klm012",
    tags: ["tipping", "restaurant", "cheap", "service", "cocktails"]
  },
  %{
    title: "Neighbor who steals packages then acts surprised when confronted",
    body: "Caught on Ring camera taking my Amazon delivery. 'Oh that was yours? I thought it was mine!' Different address, different name, Kyle.",
    url: "https://reddit.com/r/packages/comments/nop345",
    tags: ["packages", "stealing", "neighbors", "ring_camera", "lying"]
  },
  %{
    title: "Guy who spoils movies in the group chat immediately after seeing them",
    body: "Endgame spoilers 2 hours after release. No warning, no spoiler tags, just pure chaos and ruined weekends.",
    url: "https://reddit.com/r/movies/comments/qrs678",
    tags: ["spoilers", "movies", "group_chat", "inconsiderate", "endgame"]
  },
  %{
    title: "Dude who argues with referees at kids' soccer games",
    body: "It's 8-year-olds playing recreational soccer, but this man is out here screaming about offside calls like it's the World Cup.",
    url: "https://reddit.com/r/parenting/comments/tuv901",
    tags: ["soccer", "kids", "referee", "screaming", "sports_parent"]
  },
  %{
    title: "Guy who brings smelly food to movie theaters",
    body: "Full Chinese takeout, extra garlic. During a quiet dramatic scene. The auditorium now smells like orange chicken.",
    url: "https://reddit.com/r/movietheaters/comments/wxy234",
    tags: ["movie_theater", "food", "smell", "chinese_takeout", "etiquette"]
  },
  %{
    title: "Coworker who uses all the printer paper and never refills it",
    body: "Prints 200-page documents, empties three trays, walks away. Next person discovers the wasteland he left behind.",
    url: "https://reddit.com/r/office/comments/zab567",
    tags: ["printer", "paper", "office", "inconsiderate", "refill"]
  },
  %{
    title: "Guy who takes up two seats on public transport with his bag",
    body: "Backpack gets its own seat while pregnant ladies stand. Peak public transport villain behavior.",
    url: "https://reddit.com/r/publictransport/comments/cde890",
    tags: ["public_transport", "seats", "bag", "pregnant", "inconsiderate"]
  },
  %{
    title: "Dude who talks during entire movies and gets mad when asked to stop",
    body: "'I paid for my ticket too!' Yes, to watch the movie, not to provide director's commentary to strangers.",
    url: "https://reddit.com/r/movies/comments/fgh123",
    tags: ["movies", "talking", "commentary", "theater", "annoying"]
  },
  %{
    title: "Guy who revs his motorcycle at 11 PM in residential neighborhoods",
    body: "Harley Davidson go BRRRRR at bedtime. Babies crying, dogs barking, Karen posting on Nextdoor.",
    url: "https://reddit.com/r/motorcycles/comments/ijk456",
    tags: ["motorcycle", "noise", "late_night", "residential", "revving"]
  },
  %{
    title: "Coworker who microwaves popcorn and burns it every single time",
    body: "The smoke alarm is basically his kitchen timer at this point. How do you mess up microwave popcorn consistently?",
    url: "https://reddit.com/r/kitchenfails/comments/lmn789",
    tags: ["popcorn", "microwave", "burning", "smoke_alarm", "office"]
  },
  %{
    title: "Guy who doesn't pick up his dog's poop but judges other dog owners",
    body: "'Some people are so irresponsible with their pets,' he says, stepping over the gift his golden retriever left yesterday.",
    url: "https://reddit.com/r/dogs/comments/opq012",
    tags: ["dogs", "poop", "irresponsible", "judgemental", "hypocrite"]
  },
  %{
    title: "Dude who always 'forgets' his wallet when the check comes",
    body: "Amazing how his memory works fine until it's time to pay. Then suddenly he's got financial amnesia.",
    url: "https://reddit.com/r/cheapskates/comments/rst345",
    tags: ["wallet", "check", "paying", "cheap", "convenient_memory"]
  },
  %{
    title: "Guy who leaves shopping carts in parking spaces instead of the corral",
    body: "Cart return is literally 10 feet away, but those 10 feet might as well be Mount Everest.",
    url: "https://reddit.com/r/shoppingcarts/comments/uvw678",
    tags: ["shopping_carts", "parking", "lazy", "corral", "inconsiderate"]
  },
  %{
    title: "Neighbor who plays bass at all hours and claims it's 'practicing'",
    body: "3 AM bass solos are not practice, they're terrorism. Learn 'Seven Nation Army' on your own time.",
    url: "https://reddit.com/r/neighbors/comments/yxz901",
    tags: ["bass", "music", "late_night", "practicing", "noise"]
  },
  %{
    title: "Guy who uses the last of the coffee and doesn't make a new pot",
    body: "Office coffee vulture strikes again. Takes the last cup, leaves the empty pot, disappears into the ether.",
    url: "https://reddit.com/r/office/comments/abc234",
    tags: ["coffee", "office", "last_cup", "empty_pot", "selfish"]
  },
  %{
    title: "Dude who brings acoustic guitar to camping trips uninvited",
    body: "We wanted to hear nature sounds, not your rendition of 'Blackbird' for the 47th time this weekend.",
    url: "https://reddit.com/r/camping/comments/def567",
    tags: ["camping", "guitar", "acoustic", "uninvited", "nature"]
  },
  %{
    title: "Guy who always has to one-up everyone's stories",
    body: "'Oh you went to Paris? Well I went to Paris AND London AND Tokyo in the same week.' Cool story, Marco Polo.",
    url: "https://reddit.com/r/conversations/comments/ghi890",
    tags: ["one_upping", "stories", "travel", "competitive", "annoying"]
  },
  %{
    title: "Coworker who eats other people's lunches and acts confused when confronted",
    body: "'I thought it was communal!' No Kevin, your name wasn't on my sandwich, my name was.",
    url: "https://reddit.com/r/officetheft/comments/jkl123",
    tags: ["lunch", "stealing", "office", "communal", "confusion"]
  },
  %{
    title: "Guy who double-dips chips at parties like it's his personal bowl",
    body: "The salsa is not your personal dipping sauce, Brad. We all saw what you did there.",
    url: "https://reddit.com/r/partyfails/comments/mno456",
    tags: ["double_dipping", "chips", "salsa", "party", "gross"]
  },
  %{
    title: "Dude who FaceTimes in public without headphones",
    body: "The entire train car is now part of your family drama, whether we wanted to be or not.",
    url: "https://reddit.com/r/publictransport/comments/pqr789",
    tags: ["facetime", "public", "headphones", "family_drama", "train"]
  },
  %{
    title: "Guy who takes forever at the ATM and checks his balance 5 times",
    body: "It's an ATM, not a financial planning session. There are 8 people behind you, Harold.",
    url: "https://reddit.com/r/banking/comments/stu012",
    tags: ["atm", "slow", "balance", "queue", "financial"]
  },
  %{
    title: "Neighbor who borrows tools and returns them broken or dirty",
    body: "'Hey can I borrow your drill?' Sure. Gets it back three weeks later covered in concrete with a stripped bit.",
    url: "https://reddit.com/r/tools/comments/vwx345",
    tags: ["tools", "borrowing", "broken", "dirty", "neighbor"]
  },
  %{
    title: "Guy who stands too close in line and breathes down your neck",
    body: "Personal space is a concept, not a suggestion. I can feel your lunch choices through my shoulder blades.",
    url: "https://reddit.com/r/personalspace/comments/yza678",
    tags: ["personal_space", "line", "breathing", "close", "uncomfortable"]
  },
  %{
    title: "Dude who drives slow in the left lane then gets mad when people pass",
    body: "55 in a 70, left lane, angry honking when anyone goes around him. Traffic vigilante strikes again.",
    url: "https://reddit.com/r/driving/comments/bcd901",
    tags: ["driving", "left_lane", "slow", "passing", "road_rage"]
  },
  %{
    title: "Guy who takes up the entire armrest and acts like it's his throne",
    body: "Airplane armrest territory wars. His elbow has claimed both sides and established a small dictatorship.",
    url: "https://reddit.com/r/flying/comments/efg234",
    tags: ["airplane", "armrest", "territory", "selfish", "flying"]
  },
  %{
    title: "Coworker who uses speakerphone for every call in open office",
    body: "We've all become unwilling participants in his customer service calls, family drama, and doctor appointments.",
    url: "https://reddit.com/r/openoffice/comments/hij567",
    tags: ["speakerphone", "office", "calls", "open_office", "privacy"]
  },
  %{
    title: "Guy who brings outside food to restaurants and acts offended when asked to leave",
    body: "'But I bought drinks!' Sir, you brought a full McDonald's meal into our steakhouse. That's not how this works.",
    url: "https://reddit.com/r/restaurants/comments/klm890",
    tags: ["restaurant", "outside_food", "mcdonalds", "policy", "offended"]
  },
  %{
    title: "Dude who monopolizes gym equipment with 20-minute rest periods",
    body: "Sitting on the bench press scrolling Instagram while people wait. That's not a rest, that's a vacation.",
    url: "https://reddit.com/r/gym/comments/nop123",
    tags: ["gym", "equipment", "rest_periods", "monopolizing", "instagram"]
  },
  %{
    title: "Guy who returns items to stores after clearly using them for months",
    body: "'This vacuum doesn't work.' Sir, there's a family of dust bunnies that have established citizenship in this filter.",
    url: "https://reddit.com/r/retail/comments/qrs456",
    tags: ["returns", "used_items", "vacuum", "months", "retail"]
  },
  %{
    title: "Neighbor who lets his dog bark at 5 AM and says 'dogs will be dogs'",
    body: "Yes, dogs will be dogs, but owners should be responsible. Your golden retriever is not a rooster.",
    url: "https://reddit.com/r/neighbors/comments/tuv789",
    tags: ["dog", "barking", "early_morning", "responsible", "excuse"]
  },
  %{
    title: "Guy who takes the elevator up one floor instead of using stairs",
    body: "The stairs are right there. You're going to the second floor. Your legs work. This is not Everest.",
    url: "https://reddit.com/r/elevators/comments/wxy012",
    tags: ["elevator", "one_floor", "stairs", "lazy", "second_floor"]
  },
  %{
    title: "Dude who argues with cashiers about expired coupons from 2019",
    body: "'But I've been saving this!' Sir, this coupon is older than the pandemic. Let it go.",
    url: "https://reddit.com/r/retail/comments/zab345",
    tags: ["coupons", "expired", "arguing", "cashier", "2019"]
  },
  %{
    title: "Guy who takes phone calls during movies and shushes people who complain",
    body: "'Hold on, I'm in a movie... SHHH!' The irony is lost on him completely.",
    url: "https://reddit.com/r/movies/comments/cde678",
    tags: ["phone_calls", "movies", "shushing", "irony", "complaints"]
  },
  %{
    title: "Coworker who reheats curry in the microwave and sets off smoke alarms",
    body: "The entire building evacuated because Derek needed his vindaloo at exactly 98.6 degrees.",
    url: "https://reddit.com/r/office/comments/fgh901",
    tags: ["curry", "microwave", "smoke_alarm", "evacuation", "vindaloo"]
  },
  %{
    title: "Guy who parks his truck across three handicap spots",
    body: "'My truck is too big for regular spots!' Your truck is too big for basic human decency too, apparently.",
    url: "https://reddit.com/r/parking/comments/ijk234",
    tags: ["truck", "handicap", "three_spots", "big", "decency"]
  },
  %{
    title: "Dude who uses the express lane with 47 items and argues about the count",
    body: "'This bag of apples counts as one item!' That's not how counting works, mathematics professor.",
    url: "https://reddit.com/r/grocery/comments/lmn567",
    tags: ["express_lane", "47_items", "counting", "apples", "arguing"]
  }
]

# More realistic tag distribution - some tags should be more common
common_tags = ["annoying", "inconsiderate", "selfish", "office", "neighbor", "rude"]
uncommon_tags = ["vindaloo", "everest", "dictatorship", "terrorism", "rooster"]

IO.puts "Creating #{length(reddit_posts)} blips for 'that_guy' vibe..."

Enum.each(reddit_posts, fn post_data ->
  # Add some random additional common tags to make distribution more realistic
  extra_tags = Enum.take_random(common_tags, :rand.uniform(3))
  all_tags = (post_data.tags ++ extra_tags) |> Enum.uniq()
  
  blip_params = %{
    uri: "at://blonk.app/blip/#{Ecto.UUID.generate()}",
    cid: "bafyrei#{:crypto.strong_rand_bytes(32) |> Base.encode32(case: :lower, padding: false)}",
    author_did: "did:plc:6e6n5nhhy7s2zqr7wx4s6p52",
    title: post_data.title,
    body: post_data.body,
    url: post_data.url,
    tags: all_tags,
    vibe_id: that_guy_vibe.id,
    vibe_uri: that_guy_vibe.uri,
    grooves_looks_good: :rand.uniform(50),  # Random groove counts
    grooves_shit_rips: :rand.uniform(20),
    indexed_at: DateTime.utc_now()
  }
  
  case Blips.create_blip(blip_params) do
    {:ok, blip} ->
      IO.puts "✓ Created blip: #{String.slice(blip.title, 0, 50)}..."
    {:error, changeset} ->
      IO.puts "✗ Failed to create blip: #{inspect(changeset.errors)}"
  end
end)

# Print tag frequency analysis
all_blips = Repo.all(
  from b in Blip, 
  where: b.vibe_id == ^that_guy_vibe.id,
  select: b.tags
)

tag_frequency = 
  all_blips
  |> List.flatten()
  |> Enum.frequencies()
  |> Enum.sort_by(&elem(&1, 1), :desc)

IO.puts "\n🏷️  Tag Frequency Analysis for 'that_guy' vibe:"
IO.puts "=" <> String.duplicate("=", 50)

Enum.each(tag_frequency, fn {tag, count} ->
  bar_length = div(count * 20, elem(Enum.at(tag_frequency, 0), 1))
  bar = String.duplicate("█", bar_length)
  IO.puts "#{String.pad_trailing(tag, 20)} #{String.pad_leading(to_string(count), 3)} #{bar}"
end)

IO.puts "\n✅ Seeded #{length(reddit_posts)} blips for 'that_guy' vibe!"
IO.puts "📊 Total unique tags: #{length(tag_frequency)}"
IO.puts "🔥 Most common tag: #{elem(Enum.at(tag_frequency, 0), 0)} (#{elem(Enum.at(tag_frequency, 0), 1)} occurrences)"