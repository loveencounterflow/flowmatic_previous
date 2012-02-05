

.. image:: https://github.com/loveencounterflow/FLOWMATIC/raw/master/artwork/flowmatic-logo-4a.png
   :align: left

The Mythical Next Beast.


WTF?
============================================================================================================

Like SillyPutty, but not as brittle. Like Perl, but less cryptic. Like Python, but sans the Batteries, and less braces. Or, like, braces all over the place, if it's that what you want. Like CoffeeScript, but with a sound dose of identity crisis. Like Brainfuck, but completely different. An exploratorium for programming language lovers. Touch it the right way and enjoy the purr. Touch it the wrong way and watch it bitching and crashing. Awesome.


FTW!
============================================================================================================

So i was looking for my next favorite programming language in 1999 and, *Lo*, there was JavaScript. After dealing with one linguistic atrocity too much, however, i was quick to dump it, having just discovered Python (then the new, slash, kewl kid on the block), which—after Basic, Assembler, Forth, VisualBasic, C (never got beyond 'Helo World', tho), Java (still traumatized by that one), and **$#%** Perl—seemed like a *sane* thing to do for a change.

I spent the twenty-zero years writing my programs in Python—quite to the exclusion of other options, but still hunting the mythical next beast. I immediately fell in love with significant whitespace and dived into classical object-oriented programming (which, be it said, is better done and easier to grasp in Python than in *any* other language i'm aware of). I pulled off *all* the pranks you can pull off in Python and OOP (like, multiple inheritance, decorators, factories, metaclasses, deep magic, and i even touched the gory innards of the import statement) only to find out that most of this stuff is about as useful as a talking toaster when you're out bungee jumping without the rope. You don't. Need. Any. Of. This.

Then one sunny day in the summer of 2011 a friend phoned in for proposals what to base his upcoming software on. I suggested Python 3 and was met with fairly acute criticism. I had to concur that i had grown to find a lot of things about the Python culture tiresome, the open sore being the sluggish adoption of Py3k and, even worse, the almost complete ignorance of state-of-the-art paradigms like asynchronous, event-based web serving. Basically, Python, WSGI, web servers and frameworks, even the way the language is being grown and how the standard library has become a fossilized monument to the glorious past (OSS anyone?), all of these aspects make Python taste, well, slightly moldy. We had also years ago walked together the Ruby on Rails way of life, and boy was i happy to be off *that* train again, so i wouldn't even mention it.

Instead i muttered words, like, *node*, c'magain, right, *NodeJS*, and, ehrm, what was that funny language i had stumbled across weeks ago, *CoffeeScript*?—OK NodeJS is JavaScript, do we want that? Risk getting buried in braces? Like you wouldn't touch Lisp with a long stick for fear of getting stuck between gazillions of hopefully matching staples, right?—Hey, CoffeeScript runs on NodeJS! Woot!—Wow look at the sheer number of modules for NodeJS. OMG this thing is only two years old! Holy cow this motherfucker is growing like a freckin Borg hive assimilating brains.—Wow CoffeeScript *looks* like Python so let's give it a try. How do we install that thing?—Look there is this *npm* thing, ``npm install coffee-script``... wait, no ``sudo``? Local installs? Woot. I've been doing that for years, alwas fighting the grain of Python whose developers insist that my own modules should be hidden in ``/usr/foo/fuck`` or wherever.

So that's the short of what was like a landslide, an epiphany, a good summer. I more or less immediately stopped to care about Python and set off to rebuild my ≈50k LOC utility belt library (now in its third incarnation) that will power, you guessed it, FlowMatic.


What gives?
============================================================================================================

Anyone who cares about implementing their own programming language must need be answer two core questions: **What to implement the virtual machine in**, and **how to parse source**. Let me quickly answer the first question: FlowMatic targets CoffeeScript, which is then transposed to JavaScript, which runs on NodeJS, which is based on V8, which is Google's awesome JavaScript VM that also powers Google Chrome. Code that does not rely on NodeJS features (such as filesystem access) can also seemlessly run in the browser, which is one reason why folks are flocking to JavaScript in great numbers these days. However, conceived to bring a new feeling of freedom, love, and simplicity to programming (yay!), while the *implementation* of FlowMatic will for the foreseeable future rely on CoffeeScript and NodeJS, it is an explicit goal to transpose FlowMatic to other languages than CoffeeScript.

The second question makes me moan a little coming to think of it. I cannot count the tools and concepts around the subject of parsing that i have tried to read and understand. It is a hairy subject, and one in which traditionalist nerds excel at building arcane architectures that look every bit as impregnable as Clark Kent's Fortress of Solitude. To wit, have a look at `Changing CPython’s Grammar`_

.. _Changing CPython’s Grammar: http://docs.python.org/devguide/grammar.html







