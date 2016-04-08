# lua-scripts
Lua scripts - a very powerful means of customizing the IMPRS™ Portal to perform advanced monitoring tasks.

Vaonet has incorporated Lua into the IMPRS™ product line with the intention of giving you a very powerful means of customizing the system to perform advanced monitoring tasks not easily accomplished through existing mechanisms. Along the way, we have made a few modifications to the core Lua libraries and also extended Lua's functionality to support and access some IMPRS-specific features.

Vaonet Lua is fully compatible with Lua 5.1. It supports almost all standard Lua library functions and the full set of Lua API functions. Vaonet Lua also extends the standard Lua virtual machine (VM) with new functionality and adds several extension modules. 

But the most exciting feature of Vaonet Lua is that it implements a unique and extremely fast just-in-time compiler for executing scripts. As a scripting session is created, the associated script is compiled to actual x86 instructions. In so doing, the script execution speed is phenomenally fast because the script runs at the same speed as a native program would. When comparing Vaonet Lua execution speed with other interpreted language execution speeds, the results are jaw-dropping. For instance, one benchmark put the compiled version of an md5 hashing script running 135 times faster than the interpreted version of that same script!
