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

Let's see how this pans out.
This implementation will be critical for our mental model of how we want all this to tie together.
