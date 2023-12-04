luaunit = require('luaunit')

-- @enum TYPE
local TYPE = {
    NUMC = "NumC",
    IDC = "IdC",
    STRINGC = "StringC",
    APPC = "AppC",
    IFC = "IfC",
    LAMC = "LamC"
}

-- @enum VALUETYPE
local VALUETYPE = {
    NUMV = "NumV",
    STRINGV = "StringV",
    BOOLV = "BoolV",
    CLOSV = "ClosV",
    PRIMOPV = "PrimopV"
}

-- Env table<String, Value>
topenv = {
    ["+"] = {
        type = VALUETYPE.PRIMOPV,
        value = "+"
    },
    ["-"] = {
        type = VALUETYPE.PRIMOPV,
        value = "-"
    },
    ["/"] = {
        type = VALUETYPE.PRIMOPV,
        value = "/"
    },
    ["*"] = {
        type = VALUETYPE.PRIMOPV,
        value = "*"
    },
    ["<="] = {
        type = VALUETYPE.PRIMOPV,
        value = "<="
    },
    ["equal?"] = {
        type = VALUETYPE.PRIMOPV,
        value = "equal?"
    },
    ["true"] = {
        type = VALUETYPE.BOOLV,
        value = true
    },
    ["false"] = {
        type = VALUETYPE.BOOLV,
        value = false
    }
}

-- Concrete Syntax
-- ExprC = NumC | IdC | StringC | AppC | IfC | LamC

-- Abstract Syntax
-- Expr ::= Num
--       | id
--       | String
--       | {Expr ? Expr else: Expr}
--       | {with [Expr as id] ... : Expr}
--       | {blam {id ...} Expr}
--       | {Expr Expr}

-- Value = NumV | BoolV | StringV | ClosV | PrimopV 

-- Table NumV
-- @NamedField type TYPE
-- @NamedField value Number

-- Table ClosV
-- @NamedField type TYPE
-- @NamedField args [String]
-- @NamedField body ExprC
-- @NamedField env Env

-- Table NumC
-- @NamedField type TYPE
-- @NamedField value Number

numC = {
    type = TYPE.NUMC,
    value = 1
}

-- Table IdC
-- @NamedField type TYPE
-- @NamedField value String

idC = {
    type = TYPE.IDC,
    value = "x"
}

-- Table StringC
-- @NamedField type TYPE
-- @NamedField value String

stringC = {
    type = TYPE.STRINGC,
    value = "HELLO WORLD"
}

-- Table AppC
-- @NamedField type TYPE
-- @NamedField fun ExprC
-- @NamedField args [ExprC]

appC = {
    type = TYPE.APPC,
    fun = {
        type = TYPE.IDC,
        value = "+"
    },
    args = {{
        type = TYPE.NUMC,
        value = 2
    }}
}

-- Table IfC
-- @NamedField type TYPE
-- @NamedField iff ExprC
-- @NamedField thenf ExprC
-- @NamedField elsef ExprC
ifC = {
    type = TYPE.IFC,
    iff = {
        type = TYPE.APPC,
        fun = {
            type = TYPE.IDC,
            value = "-"
        },
        args = {{
            type = TYPE.NUMC,
            value = 2
        }, {
            type = TYPE.NUMC,
            value = 3
        }}
    },
    thenf = {
        type = TYPE.NUMC,
        value = 1
    },
    elsef = {
        type = TYPE.NUMC,
        value = 0
    }
}

-- Table LamC
-- @NamedField type TYPE
-- @NamedField args [String]
-- @NamedField body ExprC

lamC = {
    type = TYPE.LAMC,
    args = {"x", "y"},
    body = {
        type = TYPE.APPC,
        fun = "+",
        args = {{
            type = TYPE.IDC,
            value = "x"
        }, {
            type = TYPE.IDC,
            value = "y"
        }}
    }
}

print(lamC.type)
print(lamC.args)
print(lamC.body.type)
print(lamC.body.args[1].value)

-- @param var String 
-- @param env Env 
-- @return Value
function lookup(var, env)
    for k, v in pairs(env) do
        if k == var then
            return v
        end
    end
    error("PAIG: lookup - var " .. var .. " not in env")
end

-- print(lookup("+", topenv).value)

-- @param expr ExprC 
-- @param env Env
-- @return Value
function interp(expr, env)
    if expr.type == TYPE.NUMC then
        return {
            type = VALUETYPE.NUMV,
            value = expr.value
        }
    elseif expr.type == TYPE.STRINGC then
        return {
            type = VALUETYPE.STRINGV,
            value = expr.value
        }
    elseif expr.type == TYPE.IDC then
        return lookup(expr.value, env)
    elseif expr.type == TYPE.LAMC then
        return {
            type = VALUETYPE.CLOSV,
            args = expr.args,
            body = expr.body,
            env = env
        }
    elseif expr.type == TYPE.APPC then
        fd = interp(expr.fun, env)
        if fd.type == VALUETYPE.PRIMOPV then
            return applyPrimop(fd, expr.args, env)
        end
    elseif expr.type == TYPE.IFC then
        cond = interp(expr.iff, env)
        if cond.type ~= VALUETYPE.BOOLV then
            error("if expected boolean condition, got " .. cond.type)
        end
        if cond.value then
            return interp(expr.thenf, env)
        end
        return interp(expr.elsef, env)
    end
end

function applyPrimop(primop, args, env)
    if #args ~= 2 then
        error("PAIG: function expected 2 args, got " .. #args)
    end

    firstArg = interp(args[1], env)
    secondArg = interp(args[2], env)

    if firstArg.type ~= VALUETYPE.NUMV or secondArg.type ~= VALUETYPE.NUMV then
        error("PAIG: function expected numbers, got " .. firstArg.type .. secondArg.type)
    end

    if primop.value == "+" then
        return {
            type = VALUETYPE.NUMV,
            value = firstArg.value + secondArg.value
        }
    elseif primop.value == "-" then
        return {
            type = VALUETYPE.NUMV,
            value = firstArg.value - secondArg.value
        }
    elseif primop.value == "*" then
        return {
            type = VALUETYPE.NUMV,
            value = firstArg.value * secondArg.value
        }
    elseif primop.value == "/" then
        if secondArg.value == 0 then
            error("PAIG: division by zero")
        end
        return {
            type = VALUETYPE.NUMV,
            value = firstArg.value / secondArg.value
        }
    elseif primop.value == "<=" then
        return {
            type = VALUETYPE.BOOLV,
            value = firstArg.value <= secondArg.value
        }
    elseif primop.value == "equal?" then
        return {
            type = VALUETYPE.BOOLV,
            value = firstArg.value == secondArg.value
        }
    end
end

-- Tests
TestMyStuff = {}
function TestMyStuff:testLessthanEqual()
    result = interp({
        type = TYPE.APPC,
        fun = {
            type = TYPE.IDC,
            value = "<="
        },
        args = {{
            type = TYPE.NUMC,
            value = 5
        }, {
            type = TYPE.NUMC,
            value = 3
        }}
    }, topenv).value
    luaunit.assertEquals(type(result), 'boolean')
    luaunit.assertEquals(result, false)
end

function TestMyStuff:testEqualFalse()
    result = interp({
        type = TYPE.APPC,
        fun = {
            type = TYPE.IDC,
            value = "equal?"
        },
        args = {{
            type = TYPE.NUMC,
            value = 5
        }, {
            type = TYPE.NUMC,
            value = 3
        }}
    }, topenv).value
    luaunit.assertEquals(type(result), 'boolean')
    luaunit.assertEquals(result, false)
end

function TestMyStuff:testEqualTrue()
    result = interp({
        type = TYPE.APPC,
        fun = {
            type = TYPE.IDC,
            value = "equal?"
        },
        args = {{
            type = TYPE.NUMC,
            value = 4
        }, {
            type = TYPE.NUMC,
            value = 4
        }}
    }, topenv).value
    luaunit.assertEquals(type(result), 'boolean')
    luaunit.assertEquals(result, true)
end

function TestMyStuff:testAddNums()
    result = interp({
        type = TYPE.APPC,
        fun = {
            type = TYPE.IDC,
            value = "+"
        },
        args = {{
            type = TYPE.NUMC,
            value = 2
        }, {
            type = TYPE.NUMC,
            value = 3
        }}
    }, topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, 5)
end

function TestMyStuff:testSubtractNums()
    result = interp({
        type = TYPE.APPC,
        fun = {
            type = TYPE.IDC,
            value = "-"
        },
        args = {{
            type = TYPE.NUMC,
            value = 20
        }, {
            type = TYPE.NUMC,
            value = 121
        }}
    }, topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, -101)
end

function TestMyStuff:testId()
    result = interp({
        type = TYPE.IDC,
        value = "true"
    }, topenv).value
    luaunit.assertEquals(type(result), 'boolean')
    luaunit.assertEquals(result, true)
end

function TestMyStuff:testNumC()
    result = interp({
        type = TYPE.NUMC,
        value = 4
    }, topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, 4)
end

function TestMyStuff:testIf()
    result = interp({
        type = TYPE.IFC,
        iff = {
            type = TYPE.APPC,
            fun = {
                type = TYPE.IDC,
                value = "<="
            },
            args = {{
                type = TYPE.NUMC,
                value = 2
            }, {
                type = TYPE.NUMC,
                value = 3
            }}
        },
        thenf = {
            type = TYPE.NUMC,
            value = 1
        },
        elsef = {
            type = TYPE.NUMC,
            value = 0
        }
    }, topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, 1)
end

luaunit.LuaUnit.run()

