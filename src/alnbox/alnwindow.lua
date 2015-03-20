-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

-- starts interactive pager in curses window
-- Arguments:
-- 1. curses window
-- 2. table of properties:
--  * rows -- number of rows
--  * cols -- number of cols
--  * getCell -- function (row, col) -> table of fields:
--      character, foreground, background,
--      bold, blink, underline
--  * top_headers -- number of top header rows
--  * left_headers -- number of left header rows
--  * right_headers -- number of right header rows
--  * bottom_headers -- number of bottom header rows
--  * getTopHeader -- function(row, col) -> table of fields
--  * getLeftHeader -- function(row, col) -> table of fields
--  * getRightHeader -- function(row, col) -> table of fields
--  * getBottomHeader -- function(row, col) -> table of fields
-- Result:
-- Object with the following methods:
--  * drawAll
--  * moveUp
--  * moveDown
--  * moveLeft
--  * moveRight
return function(window, p)
    assert(p.rows >= 1)
    assert(p.cols >= 1)

    assert(not p.top_headers or p.getTopHeader)
    assert(not p.left_headers or p.getLeftHeader)
    assert(not p.bottom_headers or p.getBottomHeader)
    assert(not p.right_headers or p.getRightHeader)

    assert(p.getCell)

    local top_headers = p.top_headers or 0
    local left_headers = p.left_headers or 0
    local right_headers = p.right_headers or 0
    local bottom_headers = p.bottom_headers or 0

    -- enable hardware character insert/delete
    window:idcok()
    window:idlok()

    local win_rows, win_cols = window:getmaxyx()
    local table_rows = win_rows - top_headers - bottom_headers
    local table_cols = win_cols - left_headers - right_headers
    assert(table_rows >= 1)
    assert(table_cols >= 1)

    local start_row = 0
    local start_col = 0

    local function moveUp()
        if start_row > 0 then
            start_row = start_row - 1
        end
    end

    local function moveDown()
        if start_row + table_rows < p.rows then
            start_row = start_row + 1
        end
    end

    local function moveLeft()
        if start_col > 0 then
            start_col = start_col - 1
        end
    end

    local function moveRight()
        if start_col + table_cols < p.cols then
            start_col = start_col + 1
        end
    end

    local function pgetCell(row, col)
        local top_header = row < top_headers
        local left_header = col < left_headers
        local bottom_header = row + bottom_headers >= win_rows
        local right_header = col + right_headers >= win_cols
        local row1 = start_row + row - top_headers
        local col1 = start_col + col - left_headers
        if row1 >= p.rows + bottom_headers or
                col1 >= p.cols + right_headers then
            return ' '
        elseif (top_header or bottom_header) and
                (left_header or right_header) then
            return ' '
        elseif top_header then
            return p.getTopHeader(row, col1)
        elseif left_header then
            return p.getLeftHeader(row1, col)
        elseif bottom_header then
            local row2 = row - top_headers - table_rows
            return p.getBottomHeader(row2, col1)
        elseif right_header then
            local col2 = col - left_headers - table_cols
            return p.getRightHeader(row1, col2)
        else
            return p.getCell(row1, col1)
        end
    end

    local function cleanChar(ch)
        if ch == '' then
            ch = ' '
        end
        if type(ch) == 'number' and ch >= 0 and ch < 10 then
            ch = tostring(ch)
        end
        if type(ch) == 'string' then
            ch = string.byte(ch)
        end
        if type(ch) ~= 'number' then
            ch = string.byte(' ')
        end
        return ch
    end

    local function drawAll()
        for row = 0, win_rows - 1 do
            for col = 0, win_cols - 1 do
                local cell = pgetCell(row, col)
                if type(cell) ~= 'table' then
                    cell = {character=cell}
                end
                window:move(row, col)
                local fg = cell.foreground or curses.COLOR_WHITE
                local bg = cell.background or curses.COLOR_BLACK
                local makePair = require 'alnbox.makePair'
                local pair = makePair(fg, bg)
                window:attrset(curses.color_pair(pair))
                if cell.bold then
                    window:attron(curses.A_BOLD)
                end
                if cell.blink then
                    window:attron(curses.A_BLINK)
                end
                if cell.underline then
                    window:attron(curses.A_UNDERLINE)
                end
                window:addch(cleanChar(cell.character))
            end
        end
    end

    return {
        drawAll = drawAll,
        moveUp = moveUp,
        moveDown = moveDown,
        moveRight = moveRight,
        moveLeft = moveLeft,
    }
end