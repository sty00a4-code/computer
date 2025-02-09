require "class"

---@param v any
---@return boolean
function some(v)
    return type(v) ~= "nil"
end

---@generic T
---@param v T
---@param ... type|string
---@return T?
function checkType(v, ...)
    local vty = type(v)
    for _, ty in ipairs({ ... }) do
        if vty == ty then
            return v
        end
    end
end

---@param v string
---@param ... string
---@return string?
function checkLiteral(v, ...)
    if not some(checkType(v, "string")) then return end
    for _, lit in ipairs({ ... }) do
        if v == lit then
            return v
        end
    end
end

---@param v number
---@param start number?
---@param stop number?
---@return number?
function checkRange(v, start, stop)
    if not some(checkType(v, "number")) then return end
    if type(start) == "number" then
        if v < start then
            return
        end
    end
    if type(stop) == "number" then
        if v > stop then
            return
        end
    end
    return v
end

---@param t table
---@param v any
---@return boolean
function table.contains(t, v)
    for _, e in pairs(t) do
        if e == v then
            return true
        end
    end
    return false
end

---@generic T
---@param v T
---@param n integer|string
---@param ... type|string
---@return T?
function errorCheckType(v, n, ...)
    if not some(checkType(v, ...)) and not table.contains({...}, "nil") then
        error("expected table for argument #" .. n .. ", got " .. type(v), 3)
    end
end

---@generic T
---@param v T
---@param n integer|string
---@param ... type|string
---@return T?
function errorCheckLiteral(v, n, ...)
    if not some(checkLiteral(v, ...)) then
        error("expected table for argument #" .. n .. ", got " .. type(v), 3)
    end
end
