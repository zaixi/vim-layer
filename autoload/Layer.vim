
"-------------------------------------------------------------------------
" 助记系统
"-------------------------------------------------------------------------
let s:keys = []
let g:leader_key_map      = {'name' : 'leader guide'}
let g:localleader_key_map = {'name' : 'localleader guide'}
let mapleader = ";"
"let mapleader = "\<Space>"
let maplocalleader = ','
set timeoutlen=500

function! s:mapping_def(key_dict, key, value, desc)abort
  call add(s:keys, a:key[0])
  if len(a:key) > 1
    if !has_key(a:key_dict, a:key[0])
      echo "Warning: key_map" ."." .join(s:keys, '.') . " is missing name"
      let a:key_dict[a:key[0]] = {'name': ""}
    endif
    call s:mapping_def(a:key_dict[a:key[0]], a:key[1:-1], a:value, a:desc)
  else
    if has_key(a:key_dict, a:key)
      echo join(s:keys, '.') "mapping repeat:" "Mapping->" a:desc "and" a:key_dict[a:key]
    endif
    let a:key_dict[a:key] = [a:value, a:desc]
    let s:keys = []
  endif
endfunction

function! s:mapping_name(key_dict, key, name)abort
  call add(s:keys, a:key[0])
  if len(a:key) > 1
    if !has_key(a:key_dict, a:key[0])
      echo "Warning: key_map" ."." .join(s:keys, '.') . " is missing name"
      let a:key_dict[a:key[0]] = {'name': ""}
    endif
    call s:mapping_name(a:key_dict[a:key[0]], a:key[1:-1], a:name)
  else
    if !has_key(a:key_dict, a:key[0])
      let a:key_dict[a:key[0]] = {'name': a:name}
	elseif !has_key(a:key_dict[a:key], 'name')
	  let a:key_dict[a:key]['name'] =  a:name
	else
      echo "Warning: key_map" ."." .join(s:keys, '.') . " is missing name"
    endif
    let s:keys = []
  endif
endfunction

function! g:LeaderMappingName(key, name)abort
  call s:mapping_name(g:leader_key_map, a:key, a:name)
endfunction

function! g:LeaderMappingDef(key, value, desc)abort
  call s:mapping_def(g:leader_key_map, a:key, a:value, a:desc)
endfunction

function! g:LocalleaderMappingName(key, name)abort
  call s:mapping_name(g:localleader_key_map, a:key, a:name)
endfunction

function! g:LocalleaderMappingDef(key, value, desc)abort
  call s:mapping_def(g:localleader_key_map, a:key, a:value, a:desc)
endfunction

function! s:get_raw_key_mapping(key) abort
  let readmap = ''
  redir => readmap
  silent execute 'map' a:key
  redir END
  return split(readmap, "\n")
endfunction

function! s:check_key(key_dict, key, value) abort
  call add(s:keys, a:key[0])
  if len(a:key) > 1
    if !has_key(a:key_dict, a:key[0])
		let s:keys = []
    endif
    call s:check_key(a:key_dict[a:key[0]], a:key[1:-1], a:value)
  else
    if has_key(a:key_dict, a:key)
      echo join(s:keys, '.') "mapping repeat:" "Mapping->" a:value "and" a:key_dict[a:key]
    endif
    let s:keys = []
  endif
endfunction

function! s:check_key_mapping(leader, key_dict) abort
  let l:key = a:leader
  let l:key_dict = a:key_dict
  let l:lines = s:get_raw_key_mapping(l:key)

  for i in range(0, len(l:lines) - 1)
    let mapd = maparg(split(l:lines[i][3:])[0], l:lines[i][0], 0, 1)
	if mapd == {}
		continue
	endif
	call s:check_key(l:key_dict, mapd.lhs[1:-1], mapd.rhs)
    for j in range(i + 1, len(l:lines) - 1)
      let each_mapd = maparg(split(l:lines[j][3:])[0], l:lines[j][0], 0, 1)
      if mapd.lhs ==# each_mapd.lhs
        echo mapd.lhs "mapping repeat:" "Mapping->" mapd.rhs "and" each_mapd.rhs
      endif
    endfor
  endfor
endfunction

function! LeaderCheckMapping()abort
	call s:check_key_mapping(get(g:, 'mapleader', '\'), g:leader_key_map)
	call s:check_key_mapping(get(g:, 'maplocalleader', ','), g:localleader_key_map)
endfunction

function! s:GuideInit()abort

	call which_key#register(get(g:, 'mapleader', '\'), 'g:leader_key_map')
	call which_key#register(get(g:, 'maplocalleader', ','), 'g:localleader_key_map')

	nnoremap <silent> <leader>       :<c-u>WhichKey       get(g:, 'mapleader', '\')<CR>
	vnoremap <silent> <leader>       :<c-u>WhichKeyVisual get(g:, 'mapleader', '\')<CR>
	nnoremap <silent> <localleader>  :<c-u>WhichKey       get(g:, 'maplocalleader', ',')<CR>
	vnoremap <silent> <localleader>  :<c-u>WhichKeyVisual get(g:, 'maplocalleader', ',')<CR>

	autocmd! FileType which_key
	autocmd  FileType which_key set laststatus=0 noshowmode noruler
				\| autocmd BufLeave <buffer> set laststatus=2 showmode ruler
endfunction

"-------------------------------------------------------------------------
" Layer 基础
"-------------------------------------------------------------------------
let s:layers = []

function! s:define_command() abort
  command! -nargs=+ -bar PM    call PluginManager#addPlugins(<args>)
  command! -nargs=+ -bar Plug  call PluginManager#addPlugins(<args>)
  command! -nargs=+ -bar Layer call Layer#Add(<args>)
  command! -nargs=+ -bar CheckMap   call LeaderCheckMapping()
  command! -nargs=+ -bar LeaderName call s:mapping_name(g:leader_key_map, <args>)
  command! -nargs=+ -bar LeaderMap  call s:mapping_def(g:leader_key_map, <args>)
  command! -nargs=+ -bar LocalleaderName call s:mapping_name(g:localleader_key_map, <args>)
  command! -nargs=+ -bar LocalleaderMap  call s:mapping_def(g:localleader_key_map, <args>)

endfunction

function! Layer#Add(layer) abort
  if index(s:layers, a:layer) < 0
    call add(s:layers, a:layer)
  endif
endfunction

function! s:Source(file) abort
  let abspath = resolve(expand(s:layer_path.'/'.a:file.'.vim'))
  execute 'source ' fnameescape(abspath)
endfunction

function! Layer#Show() abort
  echo s:layers
endfunction

function! Layer#Init(layer_path, ...) abort
  let s:layer_path = a:layer_path
  let s:plug_path = "~/.cache/vimfiles/"
  if a:0 == 1
	  let s:plug_path = a:1
  endif
  call s:define_command()
endfunction

function! Layer#Load() abort
  call PluginManager#begin(s:plug_path)
  PM 'liuchengxu/vim-which-key'
  for layer in s:layers
	  call s:Source(layer)
  endfor
  call PluginManager#end()
  for layer in s:layers
    if exists('*Layer_{layer}_after_config')
      call Layer_{layer}_after_config()
    endif
  endfor
  call LeaderCheckMapping()
  call s:GuideInit()
endfunction
