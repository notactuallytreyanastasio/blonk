# Blonk

## What is Blonk?
ATProto reddit.
But it will be different, thats just a thing to say to make people place a vibe in their head.

Blonk doesn't have subreddits like a forum. It has loose groups of vibes.

Maybe they will just be subscribers, but maybe a vibe isnt just users it identifies but users who label themselves into it or something.

We will need to build this in a way where it is consumable on its own website.
It should have some mechanism where it creates its own lexicon or something for the links?

I dont know, we are going to walk through this together.

## Building It
I started off with a simple TypeScript project and got cooking.

You can find that in aeb0dc780a395bf6193a8dc90bd4ab4f82f66d90.

```
commit aeb0dc780a395bf6193a8dc90bd4ab4f82f66d90 (HEAD -> main)
Author: Bobby Grayson <53058768+notactuallytreyanastasio@users.noreply.github.com>
Date:   Thu Jun 19 09:53:56 2025 -0400

    Initial commit with a little structure.

    We've added the ATProto SDK and set up a really basic setup.
    It's all Claude generated, but this is a learning exercise to let's take
    a look at it.

    BlonkAgent - to be renamed, but basically our Bsky client

    POST_NSID - our namespace identifier (What is this? We'll come back to that)

    PostManager - our interface to create or retrieve posts

    `index.ts` - a super basic page skeleton

    With this I guess we can try to get some shit on a page.
```

I guess now I'm just going to see what Claude has cooked up?

Once we have some shit on a screen I can think a little more.

## The Story So Far
We have a very basic setup that will in fact put something on atproto.

We made a pull request [here](https://github.com/notactuallytreyanastasio/blonk/pull/1) that got us the basics.

So what next?

Well, first I am going to drop in React.

```
lets just drop in react, we will need it later anyways.
let's be adults about it. make sure to use the latest, and to do whatever dan abramov would do.
He's pretty good.
```

This ought to go pretty far, but we will follow up in another pull request.

[Here] is the pull request.

I am not going to give it a ton of feedback since React isn't really my lane, unless something really jumps out.

I had to have a little back and forth, but we got to something running pretty quickly.

## What now?
Well, right now it only shows blips _from us_ -- we want to see other people's too and let them submit as well.

How do we go about that? 
Well I am not sure yet.

Let's dig into some docs and ask Claude, too.

Another prompt...

```
Blips need to have a "vibe" they belong to.
"vibes" are simply a group of people and a feeling.
Its not a topic like a subreddit or a forum.
A vibe can be "Sunset Sunglasses Struts" or "doinkin right" or "dork nerd linkage" - we want people to not feel confined to a topic, but have an idea of the type of content that will come up in that circle.

What do you think a good implementation step here is?
```

This started off looking pretty sane, and we'll look at it more, but I had a quick piece of feedback for it.

```
lets add some constraints.

we dont want duplicate vibes to be able to be created.

we dont want to allow people to create vibes quite yet.

We are going to make a system where instead if enough people skeet a vibe as a #hashtag then we will create one if a certain threshold is hit via the firehose if they match a special form (#vibe-YOUR_VIBE) and make sure vibes must be something like YOUR_VIBE or your_vibe or YOURVIBE but not YOUR VIBE and make sure thats enforced both react client/server/atproto client level
```

Now, we will see where this really goes.

I kind of really like this idea of creating them by mention velocity.

So, let's see what it has come up with now.

`looks at app`

It got the concept of seeding vibes right.

There are 6 it seeded things with.

To create a vibe, 5 people must post with #vibe-SOMETHING-OR_WHATEVER and then it will be found and counted.

Once this happens, it creates the vibe so people can post in it.

Once a vibe has been filled with blips, you can fluff blips with hell_yeah's or links_good's

However, it didn't detect my first post.

```
I just posted #vibe-test_post and its not being detected.

Are you sure you are monitoring the bluesky firehose for these hashtags and not something else?

I saw it come along the wire in my other firehose monitor.
```

It wasn't detecting my vibes and tried to take some shortcuts.

So, I had it re-think that approach.


```
its failing to detect emerging vibes and we have no server logs indicating this.

that is troublesome.

we need to hash out if this firehose is even working and you are just making willy error handlers that cover important flaws in the system.

Why is it using a search to find the vibes? We should be consuming the entire firehose!
```

And then

```
We should be defining types for all this incoming data!

This is becoming incredibly hard to reason about and we still arent monitoring the firehose successfully
```

And some manual editing, comments left for it to eat up, let's see where it gets.

