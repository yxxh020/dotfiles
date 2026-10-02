" ==============================================================================
" Vim Configuration (.vimrc) - Based on manual 2212
" ==============================================================================

set number
set relativenumber
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set incsearch
set ignorecase
set smartcase
set cursorline

" vim 정규식 very magic 모드 (/ 검색 시 편리한 정규식 적용)
nnoremap / /\v
vnoremap / /\v
