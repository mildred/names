#! /usr/bin/env lua
-- See copyright notice at end of file


local function serialize(val, out, comma)
  if out == nil then
    out = {}
    comma = comma or ', '
    serialize(val, out, comma)
    return table.concat(out)
  end

  local t = type(val)
  if t == 'string' then
    out[#out+1] = ("%q"):format(val)
  elseif t == 'table' then
    out[#out+1] = '{'
    out[#out+1] = ' '
    local n = 1
    for k, v in pairs(val) do
      local tk = type(k)
      if tk == 'number' then
        if k == n then
          n = n + 1
        else
          out[#out+1] = '['
          out[#out+1] = tostring(k)
          out[#out+1] = ']='
          n = nil
        end
      elseif tk == 'string' and k:match("^[%a_][%w_]*$") and
          k ~= 'and' and k ~= 'break' and k ~= 'do' and k ~= 'else' and
          k ~= 'elseif' and k ~= 'end' and k ~= 'false' and k ~= 'for' and
          k ~= 'function' and k ~= 'if' and k ~= 'in' and k ~= 'local' and
          k ~= 'nil' and k ~= 'not' and k ~= 'or' and k ~= 'repeat' and
          k ~= 'return' and k ~= 'then' and k ~= 'true' and k ~= 'until' and
          k ~= 'while' then
        out[#out+1] = k
        out[#out+1] = '='
      else
        out[#out+1] = '['
        serialize(k, out, comma)
        out[#out+1] = ']='
      end
      serialize(v, out, comma)
      out[#out+1] = comma
    end
    out[#out] = ' }'
  else
    out[#out+1] = tostring(val)
  end
end

local function save_config(cfg, file)
  local f = io.open(file, 'w')
  f:write [[#! lua

-- This is a generated configuration file for names, a program that generates
-- names trying to guess correct sequence of letters. This file describe just
-- that: the more probable sequence of letters.

]]
  local out = {}
  serialize(cfg, out, ";\n")
  out[1] = ''
  out[2] = ''
  out[#out] = nil
  f:write(table.concat(out), "\n\n-- End of file\n")
  f:close()
end




math.randomseed(os.time())
local function rand(min, max)
  return math.random(min, max)
end
local function randf(min, max)
  return min + math.random() * (max - min)
end

local function choose_values(t)
  local k = rand(1, #t)
  return t[k], k
end

local function choose_keys(...)
  local narg = select('#', ...)
  local max = 0
  for i = 1, narg do
    -- For each argument
    local t = select(i, ...)
    if t then
      for k, v in pairs(t) do
        max = max + v
      end
    end
  end
  -- `max' contains how many transitions are possible
  -- choose in `choice' the transition to take
  local choice = randf(0, max)
  for i = 1, narg do
    -- For each argument
    local t = select(i, ...)
    if t then
      for k, v in pairs(t) do
        choice = choice - v
        if choice <= 0 then
          return k
        end
      end
    end
  end
end

-- local function choose_multiple_keys(...)
--   return choose_keys(select(rand(1, select('#', ...)), ...))
-- end



local function mark_word(cfg, mark, word, verbose, length)
  if type(mark) == "number" then
    mark = function(n)
      return n * mark
    end
  end
  local transitions = cfg.transitions
  length = length or #word
  if type(word) == 'string' then
    local w = word
    word = {}
    for i = 1, length do
      word[i] = w:sub(i, i)
    end
  end
  -- Multiply every relation used in the word by the mark
  local i = 1
  local oldl1, oldl2, newl = '', '', ''
  while i <= length do
    local l2
    oldl1, oldl2, newl = oldl2, newl, word[i]
    if not transitions[oldl2] then
      transitions[oldl2] = {}
    end
    local oldmark1 = transitions[oldl2][newl] or 0
    local newmark1 = mark(oldmark1) or oldmark1
    if verbose >= 1 then
      print(("Transition  '%s'->'%s' was %g and is now %g")
        :format(oldl2, newl, oldmark1, newmark1))
    end
    if oldl1 ~= '' then
      l2 = oldl1 .. oldl2
      if not transitions[l2] then
        transitions[l2] = {}
      end
      local oldmark2 = transitions[l2][newl] or 0
      local newmark2 = mark(oldmark2) or oldmark2
      if verbose >= 1 then
        print(("Transition '%s'->'%s' was %g and is now %g")
          :format(l2, newl, oldmark2, newmark2))
      end
      transitions[l2][newl]  = newmark2
    end
    transitions[oldl2][newl] = newmark1
    i = i + 1
  end
end


local function run_loop(cfg, interactive, numgen, capitalize, verbose, state, cfgfile, contextnum)

  -- Choose a name length
  -- Choose letters one by one
  -- Prompt the user to mark the name
  -- the mark negative if less than 1 and positive if greater than one
  -- Multiply every relation used in the word by the mark
  -- Loop
  -- Save the configuration

  numgen = numgen or 1
  contextnum = contextnum or 2
  state = state or { prefered={} }
  if not interactive and numgen <= 0 then return end

  -- Choose a name length
  local length;
  if cfg.version == 1 then
    length = choose_values(cfg.lengths)
  else
    length = choose_keys(cfg.lengths)
  end

  -- Choose letters one by one
  local word = {}
  local l1, l2 = '', ''
  while #word < length do
    local l
    if l1 ~= '' and contextnum == 2 then
      l = choose_keys(cfg.transitions[l2], cfg.transitions[l1..l2])
    else
      l = choose_keys(cfg.transitions[l2])
    end
    word[#word+1] = l
    l1, l2 = l2, l
  end
  local lowercase_word = table.concat(word)
  local display_word
  if capitalize then
    display_word = lowercase_word:sub(1, 1):upper() .. lowercase_word:sub(2)
  else
    display_word = lowercase_word
  end

  if interactive then

    -- Prompt the user to mark the name
    local mark
    repeat
      io.write(display_word)
      local nspace = 40 - #word
      if nspace < 1 then nspace = 1 end
      io.write((' '):rep(nspace))
      io.write("Mark [1-5]: ")
      mark = io.read('*l')
      io.write("\n")

      if mark == 'q' or mark == 'Q' then
        print("\n Quit.")
        local file = ''
        while file == '' do
          if cfgfile then
            assert(type(cfgfile) == 'string')
            io.write("New configuration filename [", cfgfile, "]: ")
          else
            io.write("New configuration filename: ")
          end
          file = io.read("*l")
          if cfgfile and file == '' then
            io.write("Save over ", cfgfile, "? (y/N) ")
            local ans = io.read("*l")
            if ans == 'y' or ans == 'Y' then
              file = cfgfile
            end
          end
          if file == '' then
            io.write("Are you sure you want to quit without "
              .."saving the new configuration? (Y/n) ")
            local ans = io.read("*l")
            if ans ~= 'n' and ans ~= 'N' then
              return
            end
          end
        end
        if file ~= '' then
          save_config(cfg, file)
        end
        for k, t in ipairs(state.prefered) do
          print()
          print("Names you rated "..tostring(k)..":")
          for i = 1, #t do
            print(state.prefered[k][i])
          end
        end
        return
      end

      mark = tonumber(mark)
    until type(mark) == 'number';

    if not state.prefered[mark] then
      state.prefered[mark] = { display_word }
    else
      state.prefered[mark][#state.prefered[mark]+1] = display_word
    end

    -- the mark negative if less than 1 and positive if greater than one
    -- mark [1:5] -> [0.5:1.5]
    if mark < 3 then
      mark = 2 / ( 4 - mark )
    else
      mark = ( mark - 2 ) / 2
    end
    assert(mark > 0, "mark > 0")

    mark_word(cfg, mark, word, verbose, length)

  else
    print(display_word)
  end

  -- Loop
  return run_loop(cfg, interactive, numgen-1, capitalize, verbose, state, cfgfile, contextnum)

end


local function show_help()
  print [[
NAME

    names — Generate names

SYNOPSYS

    names [OPTIONS] [CONFIG]

DESCRIPTION

    Generate names acording to the configuration file CONFIG. If no file is
    specified, a builtin configuration is used.

OPTIONS

    -h
    --help
        Show this help

    -1
        Only consider one letter of context to choose the next letter

    -2
        Consider two letters of context to choose the next letter

    -i
    --interactive
        Prompt the user each time to know if the name generated was good or not.
        Each time the user can stop the process. At the end of the process, the
        user can choose to save the modifications to the configuration file.

    -n NUM
    --num NUM
        Change the number of names generated in non interactive mode. By
        default, only one name is generated.

    -m MARK
    --mark MARK
        Mark the words on the standard input with MARK, and update the
        configuration file. MARK is a positive number, marks lower than 1 are
        negative and marks upper than 1 are positive.
        This won't overrite the CONFIG file, if you want to save the new
        configuration generated, you must use the --output option.

    -o FILE
    --output FILE
        Save the new configuration file in FILE. This is only effective with the
        option --mark

    -c CFG
    --config CFG
        Use stock config CFG

    -l
    --lowercase
        Show names all lowercase

    -u
    --uppercase
        Make uppercase the first letter of each generated name (the default)

    -v
    --verbose
        Be verbose. Can be repeated to add verbosity.

    -q
    --quiet
        Be quiet. Can be repeated.

]]
end

local function load_config(config)
  local cfg = {}
  setmetatable(cfg, { __index = _G })
  local f = assert(loadfile(config))
  setfenv(f, cfg)
  f()
  setmetatable(cfg, { __index = _G })
  return cfg
end

local function builtin_config(name)
  local cfg = { version = 2 }
  if name == "zero" then
    cfg.lengths = {}
    cfg.transitions = { ['']={} }
  else
    cfg.alphabet = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
      'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', "'" }
    --              1  2  3  4  5  6  7  8  9 10
    cfg.lengths = { 0, 0, 1, 2, 3, 3, 3, 2, 1, 1 }
    local neutral={ a=1, b=1, c=1, e=1, f=1, g=1, h=1, i=1, j=1, k=1, l=1, m=1,
      n=1, o=1, p=1, q=1, r=1, s=1, t=1, u=1, v=1, w=1, x=1, y=1, z=1, ["'"]=1 }
    local vowel=neutral
    local markv=1.5
    local markc=0.1
    local consonant={ a=markv, b=markc, c=markc, e=markv, f=markc, g=markc,
      h=markc, i=markv, j=markc, k=markc, l=markc, m=markc, n=markc, o=markv,
      p=markc, q=markc, r=markc, s=markc, t=markc, u=markv, v=markc, w=markc,
      x=markc, y=markv, z=markc, ["'"]=1 }
    cfg.transitions={ ['']=neutral, a=vowel, b=consonant, c=consonant, e=vowel,
      f=consonant, g=consonant, h=consonant, i=vowel, j=consonant, k=consonant,
      l=consonant, m=consonant, n=consonant, o=vowel, p=consonant, q=consonant,
      r=consonant, s=consonant, t=consonant, u=vowel, v=consonant, w=consonant,
      x=consonant, y=vowel, z=consonant, ["'"]=neutral }
  end
  return cfg
--   print("names: Error: no builtin configuration yet.")
--   os.exit(1)
end

local function handle_command_line(...)
  local n, max = 1, select('#', ...)
  local interactive = false
  local capitalize = true
  local output = nil
  local mark = nil
  local numgen = 1
  local verbose = 0
  local config, configfile
  local contextnum = 2
  while n <= max do
    local arg, arg2 = select(n, ...)
    if arg == '-h' or arg == '--help' then
      show_help()
      return
    elseif arg == '-i' or arg == '--interactive' then
      interactive = true
    elseif arg == '-1' then
      contextnum = 1
    elseif arg == '-2' then
      contextnum = 2
    elseif (arg == '-n' or arg == '--num') and arg2 then
      numgen = tonumber(arg2)
      n = n + 1
    elseif (arg == '-c' or arg == '--config') and arg2 then
      config = arg2
      n = n + 1
    elseif arg == '-m' or arg == '--mark' then
      mark = tonumber(arg2)
      n = n + 1
    elseif arg == '-o' or arg == '--output' then
      output = arg2
      n = n + 1
    elseif arg == '-u' or arg == '--uppercase' then
      capitalize = true
    elseif arg == '-l' or arg == '--lowercase' then
      capitalize = false
    elseif arg == '-v' or arg == '--verbose' then
      verbose = (verbose or 0) + 1
    elseif arg == '-q' or arg == '--quiet' then
      verbose = (verbose or 0) - 1
    else
      configfile = arg
      break
    end
    n = n + 1
  end
  if configfile then
    config = load_config(configfile)
    if not config.version then
      config.version = 1
    end
  else
    if verbose >= 0 then
      print("Warning: using builtin configuration file")
    end
    config = builtin_config(config)
  end
--   local reversetransitions = {}
--   for c1, t in pairs(config.transitions) do
--     for c2, mark in pairs(t) do
--       config.reversetransitions[c2] = reversetransitions[c2] or {}
--       reversetransitions[c2][c1] = mark
--     end
--   end
--   config.reversetransitions = reversetransitions
  if mark then
    local word = io.read("*l")
    while word do
      mark_word(config, function(n) return n+mark end, word, verbose)
      config.lengths[#word] = (config.lengths[#word] or 0) + 1
      word = io.read("*l")
    end
    if output then
      save_config(config, output)
    elseif verbose >= 0 then
      print("Warning: changes not saved. Use --output")
    end
  else
    run_loop(config, interactive, numgen, capitalize, verbose, nil, configfile, contextnum)
  end
end

handle_command_line(...)



-----------------------------------------------------------------------
-- Copyright (c) 2008 Mildred Ki'Lya <mildred593(at)online.fr>
--
-- Permission is hereby granted, free of charge, to any person
-- obtaining a copy of this software and associated documentation
-- files (the "Software"), to deal in the Software without
-- restriction, including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following
-- conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
-----------------------------------------------------------------------
-- kate: hl Lua 5.1 Core; indent-width 2; space-indent on; replace-tabs off;
-- kate: tab-width 8; remove-trailing-space on;
