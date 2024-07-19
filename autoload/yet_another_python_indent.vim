if exists("b:did_yet_another_python_indent")
  finish
endif
let b:did_yet_another_python_indent = 1


function! yet_another_python_indent#PythonIndent()
    " My own python indent function. The others are all just
    " don't do what I want and are maddeningly complicated
    " and hard to change.
    "
    " This function tries to do the bare minimum for the most
    " common situations when trying to code Python. It handles
    " These situations:
    " - after a colon, indent the next line

    function! WriteLog(line)
        " if the log file has been set, then do logging
        let g:vim_log_file = get(g:, 'vim_log_file', '')
        if g:vim_log_file == ''
            return
        endif

        call writefile([a:line], g:vim_log_file, 'a')
    endfunction

    call WriteLog("PythonIndent()")

    " Make a local function to do the writefile call. It can just
    " take a single string.
    let current_line = getline(v:lnum)
    " Remove the trailing comment if any from the current line
    let current_line = substitute(current_line, '\s*#.*$', '', '')
    call WriteLog("current_line: " . current_line)
    let s:this_line_indent = -1

    if current_line =~ '^\s*#'
        " If the current line is a comment, don't do anything
        return s:this_line_indent
    endif

    " Previous non-blank line
    let lnum = prevnonblank(v:lnum - 1)

    if lnum == 0
        return 0
    endif

    " Get the previous line
    let line = getline(lnum)
    call WriteLog("prevline: " . line)
    let prev_line_indent = indent(lnum)

    " These checks are for what to do based on the previous line
    " as long as the previous line is not a comment
    if prev_line_indent !~ '^\s*#'
        if line =~ ':\s*\(#.*\)\?$'
            " Indent the current line, update the `this_line_indent` var
            let s:this_line_indent = prev_line_indent + &shiftwidth
        elseif line =~ '[\[{(]$'
            " Prev line ends with a brackent, this line should be
            " one indent bigger than the previous line
            let s:this_line_indent = prev_line_indent + &shiftwidth
        elseif line =~ '^\s*\(return\|break\|continue\|raise\>\)\s*\(#.*\)\?$'
            " Prev line starts with a scope-terminating keyword, this line should be
            " one indent smaller than the previous line. Note in the regex
            " That we're using the terminating word boundary '\>' to match
            " the end of the keyword.
            let s:this_line_indent = prev_line_indent - &shiftwidth
        else
            " Indent the current line, update the `this_line_indent` var
            " (uses autoindent)
            let s:this_line_indent = -1
        endif
    endif

    function! IsInsideString()
      return synIDattr(synID(line('.'), col('.'), 1), 'name') =~? 'string'
    endfunction

    function! StartsWithComment()
      return getline('.')[col('.')-1] == '#'
    endfunction

    let s:skip_expression = 'StartsWithComment() || IsInsideString()'

    " These checks are for what to do based on the current line
    if current_line =~ '^\s*[\]})]$'
        " Let's first grab which of the brackets this line ends with
        " This will be used to find the corresponding opening bracket.
        let actual_bracket = current_line[-1:]
        " If the `actual_bracket` is a square bracket, insert a backslash
        " before it to escape it.
        if actual_bracket == ']'
            let actual_bracket = '\]'
        endif
        let corresponding_bracket = {
                    \'\]': '\[',
                    \')': '(',
                    \'}': '{'
                    \}[actual_bracket]

        call WriteLog("actual_bracket: " . actual_bracket)
        call WriteLog("corresponding_bracket: " . corresponding_bracket)

        " - Current line has a single closing bracket,
        " - AND the previous line has the corresponding opening bracket.
        "
        " In this case, the current line should be indented the same as the
        " previous line *that has the same opening bracket*.

        " Find the line with the corresponding previous opening bracket
        call cursor(0, col('.') - 1)
        call writefile(["col", col('.'), "char", getline('.')[col('.')-1]], '/tmp/vim.log', 'a')

        let open_line_number = searchpair(corresponding_bracket, '', actual_bracket, 'bW', s:skip_expression, 0)
        call writefile(["open_line_number", open_line_number], '/tmp/vim.log', 'a')
        let open_line = getline(open_line_number)
        call writefile(["open_line", open_line], '/tmp/vim.log', 'a')

        if open_line_number > 0
            call writefile(["open_line_number > 0"], '/tmp/vim.log', 'a')
            let s:this_line_indent = indent(open_line_number)
        else
            call writefile(["open_line_number NOT > 0"], '/tmp/vim.log', 'a')
            let s:this_line_indent = prev_line_indent
        endif
    elseif current_line =~ '^\s*elif.*:$'
        " We need to find the preceding `if` line and indent the current
        " line the same as that line.
        call cursor(0, 1)
        let s:searchpair_line_number = searchpair('\<if\>', '\<elif\>', '\<else\>', 'bW', s:skip_expression, 0)
        let s:this_line_indent = indent(s:searchpair_line_number)
    elseif current_line =~ '^\s*else\s*:$'
        " We need to find the preceding `if` line and indent the current
        " line the same as that line.
        call cursor(0, 1)
        let s:searchpair_line_number = searchpair('\<if\> \| \<for\> \| \<while\>', '', 'else', 'bW', s:skip_expression, 0)
        let s:this_line_indent = indent(s:searchpair_line_number)
    elseif current_line =~ '^\s*\(except\|finally\).*:$'
        " We need to find the preceding `try` line and indent the current
        " line the same as that line.
        call cursor(0, 1)
        let s:searchpair_line_number = searchpair('\<try\>', '', '\<finally\>', 'bW', s:skip_expression)
        let s:this_line_indent = indent(s:searchpair_line_number)
    elseif current_line =~ '^\s*case.*:$'
        " We need to find the preceding `case` line and indent the current
        " line the same as that line.
        call cursor(0, 1)
        call WriteLog("in case" .. s:this_line_indent)
        " This is designed to basically always find the preceding `match`.
        " It's quite hard to do anything else.
        let s:searchpair_line_number = searchpair('\<match\>', '', 'case _', 'bW', s:skip_expression)
        call WriteLog("s:searchpair_line_number: " . s:searchpair_line_number)
        let s:this_line_indent = indent(s:searchpair_line_number) + &shiftwidth
    endif

    call WriteLog("this_line_indent: " . s:this_line_indent)
    return s:this_line_indent
endfunction
