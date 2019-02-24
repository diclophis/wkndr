""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
 
" VIM, not VI
set nocompatible
set termguicolors
set background=dark
 
" General appearance and behaviour
" filetype plugin indent on
syntax on
set visualbell t_vb=
set noerrorbells
set ruler
set showcmd
set showmatch
set wildmenu
set wildmode=list:longest,full
set backspace=indent,eol,start
set nowrap
set linebreak
set lazyredraw
 
set nomodeline
 
" Indentation options
set autoindent
set expandtab
set softtabstop=2
set shiftwidth=2
set tabstop=2
set virtualedit=block
set equalprg=
 
" Search options
" set incsearch
set hlsearch
set ignorecase

" Fold options
" set foldmethod=indent

set viminfo='50,<1000,s100,h

set maxmempattern=5000

autocmd FileType make setlocal noexpandtab

au BufReadPost Wkndrfile set syntax=ruby
