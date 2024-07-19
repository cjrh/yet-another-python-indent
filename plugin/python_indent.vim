augroup PythonIndent
    autocmd!
    autocmd FileType python setlocal autoindent
    autocmd FileType python setlocal indentexpr=yet_another_python_indent#PythonIndent()
augroup END
