" Title: Yet Another Python Indentation Script
" Description: A simple Python indentation script that is easy to understand
"              and modify
" Maintainer: cjrh
augroup PythonIndent
    autocmd!
    autocmd FileType python setlocal autoindent
    autocmd FileType python setlocal indentexpr=yet_another_python_indent#PythonIndent()
augroup END
