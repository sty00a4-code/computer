BASE_TYPE = type
---@param v any
---@return type|string
function type(v)
    if BASE_TYPE(v) == "table" then
        local meta = getmetatable(v)
        if BASE_TYPE(meta) == "table" then
            if BASE_TYPE(meta.__name) == "string" then
                return meta.__name
            end
        end
    end
    return BASE_TYPE(v)
end

---@param methods table<string, function>
---@param overlaps Class[]
local function makeIndex(methods, overlaps)
    return function (self, k)
        if type(methods[k]) ~= "nil" then
            return methods[k]
        else
            for _, class in ipairs(overlaps) do
                if type(class[k]) ~= "nil" then
                    return class[k]
                end
            end
            return rawget(self, k)
        end
    end
end

---@type table<string, Class>
CLASSES = {}
---@class Class : table
---@param name string
---@param methods table<string, function>
---@return Class
function class(name, methods, ...)
    local overlaps = {...}
    local __index = makeIndex(methods, overlaps)
    local meta = {
        __name = name,
        __index = __index,
    }
    for _, class in pairs(overlaps) do
        for k, method in pairs(class) do
            if k:sub(1, 2) == "__" then
                meta[k] = method
            end
        end
    end
    for k, method in pairs(methods) do
        if k:sub(1, 2) == "__" then
            meta[k] = method
        end
    end
    local class = setmetatable({}, {
        __name = "class<"..name..">",
        __index = __index,
        __call = function(self, ...)
            local object = {}
            if type(self.__new) == "function" then
                self.__new(object, ...)
            end
            object.__class = self
            return setmetatable(object, meta)
        end,
    })
    CLASSES[name] = class
    return class
end

---@param method string
function impl(method)
    return function (self)
        error(type(self).." does not implement "..method, 2)
    end
end

return class