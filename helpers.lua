--[[
* statustimers - Copyright (c) 2022 Heals
*
* This file is part of statustimers for Ashita.
*
* statustimers is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* statustimers is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with statustimers.  If not, see <https://www.gnu.org/licenses/>.
--]]

-------------------------------------------------------------------------------
-- imports
-------------------------------------------------------------------------------
require('common');

local module = {};

local INFINITE_DURATION = 0x7FFFFFFF
REALUTCSTAMP_ID = addon.name .. ':realutcstamp'


-- convert a u32 AARRGGBB color into an ImVec4
---@param color number the colour as 32 bit argb value
---@return table color_vec ImVec4 representation of color
module.color_u32_to_v4 = function(color)
    return {
        bit.band(bit.rshift(color, 16), 0xff) / 255.0, -- red
        bit.band(bit.rshift(color,  8), 0xff) / 255.0, -- green
        bit.band(color, 0xff) / 255.0, -- blue
        bit.rshift(color, 24) / 255.0, -- alpha
    };
end

-- convert an ImVec3 to a u32 AARRGGBB color
---@param color_vec table the colour as ImVec4 argument
---@return number color 32bit rgba representation of color_vec
module.color_v4_to_u32 = function(color_vec)
    local r = color_vec[1] * 255;
    local g = color_vec[2] * 255;
    local b = color_vec[3] * 255;
    local a = color_vec[4] * 255;

    return bit.bor(
        bit.lshift(bit.band(a, 0xff), 24),  -- alpha
        bit.lshift(bit.band(r, 0xff), 16), -- red
        bit.lshift(bit.band(g, 0xff), 8), -- green
        bit.band(b, 0xff) -- blue
    );
end

module.to_roman_numerals = function(s)
    local map = { 
        I = 1,
        V = 5,
        X = 10,
        L = 50,
        C = 100, 
        D = 500, 
        M = 1000,
    }
    local numbers = { 1, 5, 10, 50, 100, 500, 1000 }
    local chars = { "I", "V", "X", "L", "C", "D", "M" }

    local RomanNumerals = { }

    s = tonumber(s)
    if not s or s ~= s then return "E" end
    if s == math.huge then return "E" end

    s = math.floor(s)
    if s <= 0 then return s end
	local ret = ""
        for i = #numbers, 1, -1 do
        local num = numbers[i]
        while s - num >= 0 and s > 0 do
            ret = ret .. chars[i]
            s = s - num
        end

        for j = 1, i - 1 do
            local n2 = numbers[j]
            if s - (num - n2) >= 0 and s < num and s > 0 and num - n2 ~= n2 then
                ret = ret .. chars[j] .. chars[i]
                s = s - (num - n2)
                break
            end
        end
    end

    if ret == 'XII' then ret = 'Bust!' end

    return ret
end


module.get_utcstamp = function()
    local ptr = AshitaCore:GetPointerManager():Get(REALUTCSTAMP_ID)
    -- double dereference the pointer to get the correct address
    ptr = ashita.memory.read_uint32(ptr)
    ptr = ashita.memory.read_uint32(ptr)
    -- the utcstamp is at offset 0x0C
    return ashita.memory.read_uint32(ptr + 0x0C)
end

module.buff_duration = function(raw_duration)
    if (raw_duration == INFINITE_DURATION) then
        return -1;
    end

    --Get time since vana'diel epoch
    local vana_base_stamp = 0x3C307D70
    local offset = module.get_utcstamp() - vana_base_stamp;    

    --Multiply it by 60 to create like terms
    local comparand = offset * 60;

    --Emulate overflow..
    comparand = bit.band(comparand, 0xFFFFFFFF);

    --Get actual time remaining..
    local real_duration = raw_duration - comparand;

    --Emulate underflow..
    if (real_duration < -2147483648) then
        real_duration = real_duration + 0xFFFFFFFF;
    end

    if (real_duration < 0) then
        return 0;
    end

    --Convert to real world miliseconds
	real_duration = real_duration * (100.0/6.0);
    return real_duration;
end

function module.table_length(t) 
    local z = 0
    if not t then return 0 end
    for _ in pairs(t) do z = z + 1 end
    return z
end

return module;
