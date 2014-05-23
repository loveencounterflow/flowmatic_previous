![](https://github.com/loveencounterflow/FLOWMATIC/raw/master/artwork/flowmatic-logo-3-1.png)


- [Synopsis](#synopsis)
- [Examples](#examples)
- [Testing](#testing)
- [Building Grammars](#building-grammars)
	- [Plain Style](#plain-style)
	- [Parametrized Style](#parametrized-style)
	- [Dependency Ordering](#dependency-ordering)
	- [Previous README](#previous-readme)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


## Synopsis


Experiments in Parser Combinators, Modular Grammars, Domain-Specific Languages (DSLs), Indentation-Based
Grammars and Symbiotic Programming Languages (that compile to JavaScript). Written in tasty CoffeeScript.

## Examples

Head over to [Arabika عربيكة](https://github.com/loveencounterflow/arabika) to see an example of a
parametrized grammar written the FlowMatic way.

## Testing

## Building Grammars

### Plain Style

### Parametrized Style

### Dependency Ordering

When `require`ing dependencies from the same grammar, take care to `require flowmatic` *before* any of the
dependencies. I have no thorough test cases for this, but it bit me once when i did

````coffeescript
# Don't do this!
XRE                       = require './9-xre'
FLOWMATIC                 = require 'flowmatic'
````

instead of

````coffeescript
# OK.
FLOWMATIC                 = require 'flowmatic'
XRE                       = require './9-xre'
````

`XRE` happens to be a function, but in the first case, i got an error `Object is not a function`, which is
indicative of NodeJS not having resolved a circular import at that point.

### Previous README

> ## TL;DR
>
> This document is mainly here to instill the illusion of meaningful content. Today i managed to reactivate my
> GitHub account, only to plunge into a session of thought-oozing, the output of which fills the rest of this
> page. I hope it is not before long that i will be able to post working code to this site, as basic parsing
> is already working quite well. Y'know, this beast is gonna have, like, inheritable, modularized grammars,
> using, like, traits, slash, mixins—? Which took me close to two weeks or so to implement (hopefully)
> correctly. The result of that work is dubbed multimix_. Don't be afraid, it won't bite, and is actually an
> extremely useful, simplistic yet feature-complete (i believe) approach to, like, inheritance the painless
> way, anyone?
>
> ..  _multimix: https://github.com/loveencounterflow/multimix
>
> ## WTF?
>
> Like SillyPutty, but not as brittle. Like Perl, but less cryptic. Like Python, but sans the Batteries, and
> less braces. Or, like, braces all over the place, if it's that what you want. Like CoffeeScript, but with a
> sound dose of identity crisis. Like Brainfuck, but completely different. An exploratorium for programming
> language lovers. Touch it the right way and enjoy the purr. Touch it the wrong way and watch it bitching and
> crashing. Awesome.
>
>
> ## FTW!
>
> So i was looking for my next favorite programming language in 1999 and, *Lo*, there was JavaScript. After
> dealing with one linguistic atrocity too much, however, i was quick to dump it, having just discovered
> Python (then the new, slash, kewl kid on the block), which—after Basic, Assembler, Forth, VisualBasic, C
> (never got beyond 'Helo World', tho), Java (still traumatized by that one), and **$#%** Perl—seemed like a
> *sane* thing to do for a change.
>
> I spent the 2000's writing my programs in Python—quite to the exclusion of other options, yet still hunting
> for the mythical next beast. I had immediately fallen in love with significant whitespace, and now dived
> into the world of classical object-oriented programming (which, be it said, is better done and easier to
> grasp in Python than in *any* other language i'm aware of). I pulled off *all* the pranks you can pull off
> in Python and OOP (like, multiple inheritance, decorators, factories, metaclasses, deep magic, and i even
> touched the gory innards of the import statement) only to find out that most of this stuff is about as
> useful as a talking toaster when you're out bungee jumping without the rope. You don't. Need. Any. Of. This.
>
> Then one sunny day in the summer of 2011 a friend phoned in for proposals what to base his upcoming software
> on. I suggested Python 3 and was met with fairly acute criticism. I had to concur that i had grown to find a
> lot of things about the Python culture tiresome, the open sore being the sluggish adoption of Py3k and, even
> worse, the almost complete ignorance of state-of-the-art paradigms like asynchronous, event-based web
> serving. Basically, Python, WSGI, web servers and frameworks, even the way the language is being grown and
> how the standard library has become a fossilized monument to the glorious past (OSS anyone?), all of these
> aspects make Python taste, well, slightly moldy. We had also years ago walked together the Ruby on Rails way
> of life, and boy was i happy to be off *that* train again, so i wouldn't even mention it.
>
> Instead i muttered words, like, *node*, c'magain, right, *NodeJS*, and, ehrm, what was that funny language i
> had stumbled across weeks ago, *CoffeeScript*?—OK NodeJS is JavaScript, do we want that? Risk getting buried
> in braces? Like you wouldn't touch Lisp with a long stick for fear of getting stuck between gazillions of
> hopefully matching staples, right?—Hey, CoffeeScript runs on NodeJS! Woot!—Wow look at the sheer number of
> modules for NodeJS. OMG this thing is only two years old! Holy cow this motherfucker is growing like a
> freckin Borg hive assimilating brains.—Wow CoffeeScript *looks* like Python so let's give it a try. How do
> we install that sucker?—Look there is this *npm* thing, ``npm install coffee-script``... wait, no ``sudo``?
> Local installs? Woot (i've been doing that for years, alwas fighting the grain of Python whose developers
> insist that my own modules should be hidden in ``/usr/foo/fuck`` or wherever).
>
> So that's the short of what was like a landslide, an epiphany, a good summer. I more or less immediately
> stopped to care about Python and set off to rebuild my ≈50k LOC utility belt library (now in its third
> incarnation) that will power, you guessed it, FlowMatic.
>
>
> ## What gives?
>
> Anyone who cares about implementing their own programming language must, need be, answer two core questions:
> **What to implement the virtual machine in**, and **how to parse source**. Let me quickly answer the first
> question: FlowMatic is written in CoffeeScript, and its primary transposing target is also CoffeeScript,
> which is then transposed to JavaScript, which runs on NodeJS, which is based on V8, which is Google's
> awesome JavaScript VM that also powers Google Chrome. Code that does not rely on NodeJS features (such as
> filesystem access) can also seamlessly run in the browser (which is one reason why folks are flocking to
> JavaScript in great numbers these days). However, conceived to bring a new feeling of freedom, love, and
> simplicity to programming (yay!), it is an explicit goal to make it simple to write and plug in components
> to transpose FlowMatic to other languages than CoffeeScript.
>
> The second question makes me moan a little coming to think of it. I cannot count the tools and concepts
> around the subject of parsing that i have tried to read and understand. It is a hairy subject, and one in
> which traditionalist nerds excel at building arcane architectures that look every bit as impregnable as
> Clark Kent's Fortress of Solitude. To wit, have a look at `Changing CPython’s Grammar`_ on Python dot org.
> The page just gives the general outline of how to do that—it modestly claims that it is 'not intended to be
> an instruction manual on Python grammar hacking', because, y'know, '[p]eople are getting this wrong all the
> time'. Seriously. Wrong. Which is unsurprising, given the convoluted process that includes touching some or
> all of these files: ``ast.c``, ``compile.c``, ``graminit.c``, ``graminit.h ``, ``Grammar``, ``keyword.py``,
> ``pyclbr``, ``Python-ast.c``, ``Python-ast.h ``, ``Python.asdl``, ``symbol.py``, ``symbtable.c``,
> ``token.py``, ``tokenizer.py``. Seriously. Wrong. Caught up in such a system you cannot even just-so play
> around with features—a single compilation of the entire VM takes ages, literally. It's like you'd just
> transformed your cuddly PC back into a mainframe from the dinosaur age where you had to apply for scheduled
> time slots, so you had better punched your cards correctly down to the last hole or else waste a day.
>
> .. _Changing CPython’s Grammar: http://docs.python.org/devguide/grammar.html
>
>
>
>
>
>
