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

-- Env = table<String, Value>
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
-- @NamedField type VALUETYPE
-- @NamedField value Number

-- Table BoolV
-- @NamedField type VALUETYPE
-- @NamedField value Boolean

-- Table StringV
-- @NamedField type VALUETYPE
-- @NamedField value String

-- Table ClosV
-- @NamedField type VALUETYPE
-- @NamedField args [String]
-- @NamedField body ExprC
-- @NamedField env Env

-- Table PrimopV
-- @NamedField type VALUETYPE
-- @NamedField value String



-- Core Syntax --
-- The following comments define the data definitions represented as Tables
-- Functions following provide a method to create the table representing the core syntax


-- Table NumC
-- @NamedField type TYPE
-- @NamedField value Number
NumC = {}
NumC.__index = NumC
function NumC:new(value)
    local numC = {}
    setmetatable(numC, NumC)
    numC.type = TYPE.NUMC
    numC.value = value
    return numC
end

-- Table IdC
-- @NamedField type TYPE
-- @NamedField value String
IdC = {}
IdC.__index = IdC
function IdC:new(value)
    local idC = {}
    setmetatable(idC, IdC)
    idC.type = TYPE.IDC
    idC.value = value
    return idC
end

-- Table StringC
-- @NamedField type TYPE
-- @NamedField value String
StringC = {}
StringC.__index = StringC
function StringC:new(value)
    local stringC = {}
    setmetatable(stringC, StringC)
    stringC.type = TYPE.STRINGC
    stringC.value = value
    return stringC
end

-- Table AppC
-- @NamedField type TYPE
-- @NamedField fun ExprC
-- @NamedField args [ExprC]
AppC = {}
AppC.__index = AppC
function AppC:new(fun, args)
    local appC = {}
    setmetatable(appC, AppC)
    appC.type = TYPE.APPC
    appC.fun = fun
    appC.args = args
    return appC
end

-- Table IfC
-- @NamedField type TYPE
-- @NamedField iff ExprC
-- @NamedField thenf ExprC
-- @NamedField elsef ExprC
IfC = {}
IfC.__index = IfC
function IfC:new(iff, thenf, elsef)
    local ifC = {}
    setmetatable(ifC, IfC)
    ifC.type = TYPE.IFC
    ifC.iff = iff
    ifC.thenf = thenf
    ifC.elsef = elsef
    return ifC
end

-- Table LamC
-- @NamedField type TYPE
-- @NamedField args [String]
-- @NamedField body ExprC
LamC = {}
LamC.__index = LamC
function LamC:new(args, body)
    local lamC = {}
    setmetatable(lamC, LamC)
    lamC.type = TYPE.LAMC
    lamC.args = args
    lamC.body = body
    return lamC
end

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

-- @param expr ExprC
-- @param env Env
-- @return Value
function interp(expr, env)
    if not expr then
        error("expected valid expr, got " .. expr)
    end

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
        if not fd then
            error("PAIG: function is invalid got " .. fd)
        end
        if fd.type == VALUETYPE.PRIMOPV then
            return applyPrimop(fd, expr.args, env)
        elseif fd.type == VALUETYPE.CLOSV then
            if #expr.args == #fd.args then
                -- add arguments to environment
                local addedEnv = {}
                spread_table(addedEnv, fd.env)
                for i = 1, #expr.args do
                    addedEnv[fd.args[i]] = interp(expr.args[i], env)
                end
                -- evaluate in new environment
                return interp(fd.body, addedEnv)
            else
                error("PAIG: expected " .. #fd.args " arguments got " .. #expr.args)
            end
        end
    elseif expr.type == TYPE.IFC then
        local cond = interp(expr.iff, env)
        if cond.type ~= VALUETYPE.BOOLV then
            error("if expected boolean condition, got " .. cond.type)
        end
        if cond.value then
            return interp(expr.thenf, env)
        end
        return interp(expr.elsef, env)
    end
end

function spread_table(dst, src)
    for k, v in pairs(src) do
        dst[k] = v
    end
    return dst
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
        fun = IdC:new("<="),
        args = { NumC:new(5), NumC:new(3) }
    }, topenv).value
    luaunit.assertEquals(type(result), 'boolean')
    luaunit.assertEquals(result, false)
end

function TestMyStuff:testEqualFalse()
    result = interp(AppC:new(IdC:new("equal?"),
        { NumC:new(5), NumC:new(3) }), topenv).value
    luaunit.assertEquals(type(result), 'boolean')
    luaunit.assertEquals(result, false)
end

function TestMyStuff:testEqualTrue()
    result = interp(AppC:new(IdC:new("equal?"),
        { NumC:new(4), NumC:new(4) }), topenv).value
    luaunit.assertEquals(type(result), 'boolean')
    luaunit.assertEquals(result, true)
end

function TestMyStuff:testAddNums()
    result = interp(AppC:new(IdC:new("+"), { NumC:new(2), NumC:new(3) }), topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, 5)
end

function TestMyStuff:testSubtractNums()
    result = interp(AppC:new(IdC:new("-"),
        { NumC:new(20), NumC:new(121) })
    , topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, -101)
end

function TestMyStuff:testId()
    result = interp(IdC:new("true"), topenv).value
    luaunit.assertEquals(type(result), 'boolean')
    luaunit.assertEquals(result, true)
end

function TestMyStuff:testNumC()
    result = interp(NumC:new(4), topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, 4)
end

function TestMyStuff:testIf()
    result = interp(IfC:new(
        AppC:new(IdC:new("<="), { NumC:new(2), NumC:new(3) }),
        NumC:new(1),
        NumC:new(0)
    ), topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, 1)
end

function TestMyStuff:testLamC()
    result = interp(
        LamC:new({ "x", "y" },
            AppC:new(IdC:new("+"), { IdC:new("x"), IdC:new("y") }))
        , topenv)
    luaunit.assertEquals(result, {
        type = VALUETYPE.CLOSV,
        args = { "x", "y" },
        body = AppC:new(IdC:new("+"), { IdC:new("x"), IdC:new("y") }),
        env = topenv
    })
    luaunit.assertEquals(result.type, VALUETYPE.CLOSV)
end

function TestMyStuff:testAppLamC()
    result = interp(AppC:new(
        LamC:new(
            { "x", "y" },
            AppC:new(IdC:new("+"),
                { IdC:new("x"), IdC:new("y") }))
        , { NumC:new(4), NumC:new(5) }), topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, 9)
end

function TestMyStuff:testNestedAppLamC()
    result = interp(AppC:new(
        LamC:new({ "h" }, AppC:new(IdC:new("h"), { NumC:new(12) })),
        { LamC:new({ "x" }, AppC:new(IdC:new("+"), { IdC:new("x"), NumC:new(4) }))}
    ), topenv).value
    luaunit.assertEquals(type(result), 'number')
    luaunit.assertEquals(result, 16)
end

luaunit.LuaUnit.run()
