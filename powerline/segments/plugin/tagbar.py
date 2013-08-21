# vim:fileencoding=utf-8:noet

import vim

from powerline.segments.vim import window_cached


@window_cached
def current_tag(pl, full_hierarchy=True):
	if not int(vim.eval('exists(":Tagbar")')):
		return
	if not full_hierarchy:
		return vim.eval('tagbar#currenttag("%s", "")')
	else:
		tag = [{
			'contents': tag,
			'draw_inner_divider': True,
			'highlight_group': ['current_tag_parent', 'current_tag'],
			} for tag in vim.eval('tagbar#currenttag("%s", "", "f")').split('.')]
		tag[-1]['highlight_group'] = ['current_tag']
		return tag
