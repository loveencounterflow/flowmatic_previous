![](https://github.com/loveencounterflow/FLOWMATIC/raw/master/artwork/flowmatic-logo-3-1.png)


- [Synopsis](#synopsis)
- [Examples](#examples)
- [Testing](#testing)
- [Building Grammars: A Code Walkthrough](#building-grammars-a-code-walkthrough)
	- [Preamble](#preamble)
	- [Options](#options)
	- [Constructor](#constructor)
		- [Constructor: Grammar Rules](#constructor-grammar-rules)
		- [Constructor: Node Producers](#constructor-node-producers)
	- [Plain Style](#plain-style)
	- [Parametrized Style](#parametrized-style)
	- [Dependency Ordering](#dependency-ordering)
	- [Previous README](#previous-readme)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


## Synopsis


Experiments in Parser Combinators, Modular Grammars, Domain-Specific Languages (DSLs), Indentation-Based
Grammars and Symbiotic Programming Languages (that compile to JavaScript). Written in tasty CoffeeScript.

## Examples

Head over to [Arabika عــربــيــكــة](https://github.com/loveencounterflow/arabika) to see an example of a
parametrized grammar written the FlowMatic way.

## Testing

## Building Grammars: A Code Walkthrough

In this section, i want to give an outline what building a FlowMatic grammar entails; as an example, i quote
from the
[assignments module](https://github.com/loveencounterflow/arabika/blob/master/src/10-assignment.coffee)
of [Arabika](https://github.com/loveencounterflow/arabika), an experiment where i try and test
the FlowMatic way of doing programming languages.

Each FlowMatic grammar module consists of two parts:

* **`@options`**: a fallback options POD. The standard grammar will be produced (with `ƒ.new.consolidate`)
  with the settings as present here.

* **`@constructor`**: a function that accepts a grammar and an options POD and attaches
  * named rules,
  * node producers,
  * language translators, and
  * test cases
  to the grammar.

We'll look at each part in turns below.

### Preamble

First up, i usually copy-and-paste something like the following to the top of my grammar files:

````coffeescript
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = '﴾10-assignment﴿'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
#..............................................................................
ƒ                         = require 'flowmatic'
BNP                       = require 'coffeenode-bitsnpieces'
````

This gives me an ample supply of logging methods with colorful outputs and a 'badge' that tells me where
outputs come from. The `ƒ` is a handy shortcut for FlowMatic; i need it all over the place so i want to
make that a snappy one. Also all over the place are references to the current grammar and its options,
which are abbreviated as `G` and `$`.

### Options

Next up is an **options POD**, which contains all the default settings of the grammar. When defining a
dialect, you often want to change some or all of these values (or introduce your own new rules):

````coffeescript
#------------------------------------------------------------------------------
@options =
  'mark':                 ':'
  'needs-lws-before':     no
  'needs-lws-after':      yes
  TEXT:                   require './2-text'
  CHR:                    require './3-chr'
  NUMBER:                 require './4-number'
  NAME:                   require './6-name'
````

In this example, since we're talking about parsing and constructing assignments, we have three settings to
influence how assignment dialects of Arabika will work: which literal is used to 'announce' the assignment
(in many languages, this would be `=`; i believe leaving the equals sign for equality testing is a better
idea), and whether there will be mandatory linear whitespace before and / or after the mark.

> Note that the options as presented
> here are maybe not optimal as they allow to define mandatory but not optional whitespace. Also, we are
> limited to linear whitespace to separate right hand side, mark, and left hand side. Then again, it's
> probably a good idea to look for a reasonable balance between complexity and flexibility.

The next items in the options POD are sub-grammars of the language; they're put inside the options instead
of the module level so they become configurable. When you want to produce an Arabika `assignment` dialect,
you may call something like `ƒ.new.grammar assignment, NAME: require 'my-name-grammar'` to change the way
variable identifiers are parsed.

### Constructor

After the options comes the constructor. In the code below, i've highlighted its three sections which deal
with defining rules, translators, and node-producing routines:


````coffeescript
#------------------------------------------------------------------------------  #  1
@constructor = ( G, $ ) ->                                                       #  2
                                                                                 #  3
  #============================================================================  #  4
  # RULES                                                                        #  5
  #----------------------------------------------------------------------------  #  6
  G._TMP_expression = ->                                                         #  7
    ### TAINT placeholder method for a more complete version of what contitutes  #  8
    an expression ###                                                            #  9
    return ƒ.or $.NUMBER.integer, $.TEXT.literal, $.NAME.route                   # 10
                                                                                 # 11
  #----------------------------------------------------------------------------  # 12
  G.assignment = ->                                                              # 13
    lws1 = if $[ 'needs-lws-before' ] then $.CHR.ilws else ƒ.drop ''             # 14
    lws2 = if $[ 'needs-lws-after'  ] then $.CHR.ilws else ƒ.drop ''             # 15
    return ƒ.seq $.NAME.route, lws1, $[ 'mark' ], lws2, ( -> G._TMP_expression ) # 16
    .onMatch ( match, state ) -> G.nodes.assignment match...                     # 17
    .describe 'assignment'                                                       # 18
                                                                                 # 19
  #============================================================================  # 20
  # TRANSLATORS                                                                  # 21
  #----------------------------------------------------------------------------  # 22
  G.assignment.as =                                                              # 23
    coffee: ( node ) ->                                                          # 24
      { lhs, mark, rhs } = node                                                  # 25
      lhs_result  = ƒ.as.coffee lhs                                              # 26
      rhs_result  = ƒ.as.coffee rhs                                              # 27
      target      = """#{lhs_result[ 'target' ]} = #{rhs_result[ 'target' ]}"""  # 28
      taints      = ƒ.as._collect_taints lhs_result, rhs_result                  # 29
      whisper taints                                                             # 30
      return target: target, taints: taints                                      # 31
                                                                                 # 32
  #============================================================================  # 33
  # NODES                                                                        # 34
  #----------------------------------------------------------------------------  # 35
  G.nodes.assignment = ( lhs, mark, rhs ) ->                                     # 36
    R                 = ƒ.new.node G.assignment.as, 'assignment'                 # 37
    R[ 'lhs'        ] = lhs                                                      # 38
    R[ 'mark'       ] = mark                                                     # 39
    R[ 'rhs'        ] = rhs                                                      # 40
    return R                                                                     # 41
````

I've found this format after going through several stages of experimental designs; the basic idea is that we
define a grammar inside a function that augments a target object (`G` for grammar). Due to the way that the
underlying [packrattle](https://github.com/robey/packrattle) parser works, the rule definitions (on lines #7
and #13) take on a rather declarative style. Let's walk through the code and see what it's all about.


#### Constructor: Grammar Rules

On **line #7**, there's a grammar rule `_TMP_expression` defined; its funny name expresses both that it's not
meant for general consumption (`_`) and to be removed later on (`TMP`). The reason is that the entire
grammar at the stage depicted here is very much in an incipient stage; as such, there's no general rule what
an expression constitutes, so i made one up to allow for test cases from early on. Later, that rule will be
swapped for a more general one (doubtless, the better way to deal with such situations is to define a
separate grammar module that can grow as the grammar grows).

As it stands, an expression is defined as an alternative (`ƒ.or`) between an integer number literal, a text
literal (a.k.a. string), or a 'route' (compound name).

> Notice i changed packrattle's `alt` to `or`; i find it more descriptive (there will be some more minor API
> changes in my [fork of packrattle](https://github.com/loveencounterflow/packrattle)).

On **line #13**, there's a rule for what constitutes an assignment; this one is a bit more involved, so let's
step through.—On lines #13 and #14, we avail ourselves of the two settings `$[ 'needs-lws-before' ]` and
`$[ 'needs-lws-after'  ]` (remember `$` here stands for the actual options POD that is valid for the
grammar we're producing; it may be different from `@options`). Based on these settings, we decide what the
space to the left and the rigth of the assignment mark—i.e. `$[ 'mark' ] == ':'`—should look like: in
case whitespace is being called for, that requirement is passed on to `$.CHR.ilws` (`CHR` being a module
to handle basic character classes and `ilws` a method to recognize and <b>i</b>gnore <b>l</b>inear
<b>w</b>hite<b>s</b>pace); in case no space is allowed, we resort to matching (and dropping) an empty
string (which trivially always matches).

**Lines 16 thru 18** build the `assignment` grammar rule proper; this one is pretty condensed and uses the
new dot notation introduced in CoffeeScript 1.7; to repeat:

```coffeescript
    return ƒ.seq $.NAME.route, lws1, $[ 'mark' ], lws2, ( -> G._TMP_expression ) # 16
    .onMatch ( match, state ) -> G.nodes.assignment match...                     # 17
    .describe 'assignment'                                                       # 18
```

The same expressed in CS < 1.7 is perhaps a bit easier to read:

```coffeescript
R = ƒ.seq $.NAME.route, lws_before, $[ 'mark' ], lws_after, ( -> G._TMP_expression )
R = R.onMatch ( match, state ) -> G.nodes.assignment match...
R = R.describe 'assignment'
return R

```
> This is very much the packrattle parser API at work: you first instantiate a rule using one of the parser
> methods, then you tack handlers like `onMatch` and `describe` onto it; each of these calls returns a
> modified version of your grammar rule, so you shouldn't return the value that results from the *first* call
> but of the *last* call, as shown above.
>
> In contradistinction to some other parser combinator libraries
> i tested, your only chance to get hold of the source is in case of a match. I'm also not sure whether i
> like the fact that dutifully adding a descriptive description means that earlier error descriptions get
> suppressed (i.e. if `$.NAME.route` should fail on an input you'll still only get `Expected assignment` as
> an error description—it would be so much more helpful to see the entire chain of failure).
>
> At this point you maybe become a little wary of all the little things that can go wrong, and you'd be
> right. It is exactly for this reason that i'm charting the course in so much detail here. We'll get into
> setting up test cases in a minute; FlowMatic comes with a custom-tailored testing method that makes it
> relatively easy to formulate and run tests. You will basically have to start out with very simple things
> and then write and run test cases from very early on.

#### Constructor: Node Producers

What we do on **line #17** is we take the match (which is a list of three elements, `[ route, mark,
expression ]`, the whitespace having been dropped) and apply to a node producer, `G.nodes.assignment` (i
omitted the `return` statement here since this is one-liner; it is a stylistic preference). This is the code
of the node producer again (you will notice we dever defined `G.nodes`; that part is done by FlowMatic
behind the scenes):

```coffeescript
G.nodes.assignment = ( lhs, mark, rhs ) ->                                     # 36
  R                 = ƒ.new.node G.assignment.as, 'assignment'                 # 37
  R[ 'lhs'        ] = lhs                                                      # 38
  R[ 'mark'       ] = mark                                                     # 39
  R[ 'rhs'        ] = rhs                                                      # 40
  return R                                                                     # 41
```

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
