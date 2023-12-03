print("Hello World")
-- comment lol

-- dyn typed lang
local x = 10
local name = "john doe"
local isAlive = false
local a = nil -- no value or invalid value

local x = 1 * 2 * 3 * 4
print(x)

local age = 12
local name = "Billy"
print(name .. " is " .. age .. " years old")

if age > 18 then
    print("over 18")
end

if age > 18 then
    print("dog")
elseif age == 18 then
    print("cat")
else
    print("mouse")
end

function printTax(price)
    local tax = price * 0.21
    print("tax: " .. tax)
end

function calcTax(price)
    return price * 0.21
end

-- while loop
local i = 0
local count = 0
while i <= 10 do
    count = count + 1
    i = i +1
end 

-- for loop
count = 0
for i=1, 5 do
    count = count + 1
end
print(count)

-- basic table (arrs, objs)
local colors = {"red", "green", "blue"}

-- 1-indexed, #colors = leng
for i=1, #colors do 
    print(colors[i])
end

table.insert(colors, "orange")
print(colors[#colors])

table.insert(colors, 2, "pink")
for i=1, #colors do 
    print(colors[i])
end

table.remove(colors, 1)
print(colors[1])

-- 2d tables
local data = {
    {"billy", 12},
    {"john", 1},
    {"andy", 45},
}

-- instead use keys fortables for data w diff types
local teams = {
    ["teamA"] = 12,
    ["teamB"] = 15
}
print(teams["teamA"])


teams["teamC"] = 1

-- remove key fr table
teams["teamA"] = nil

for key, value in pairs(teams) do
    print(key .. ":" .. value)
end