# vim:fileencoding=utf-8:noet
from __future__ import unicode_literals

from powerline import Powerline
from tests import TestCase
from tests.lib.config_mock import select_renderer
from shutil import rmtree
import os
import json
from powerline.lib import mergedicts_copy as mdc
from subprocess import check_call
from operator import add


CONFIG_DIR = 'tests/config'


root_config = lambda: {
	'common': {
		'dividers': {
			'left': {
				'hard': '#>',
				'soft': '|>',
			},
			'right': {
				'hard': '<#',
				'soft': '<|',
			},
		},
		'spaces': 0,
		'interval': None,
		'watcher': 'auto',
	},
	'ext': {
		'test': {
			'theme': 'default',
			'colorscheme': 'default',
		},
	},
}


colors_config = lambda: {
	'colors': {
		'c1': 1,
		'c2': 2,
	},
	'gradients': {
	},
}


colorscheme_config = lambda: {
	'groups': {
		'g': {'fg': 'c1', 'bg': 'c2', 'attr': []},
	}
}


theme_config = lambda: {
	'segment_data': {
		's': {
			'before': 'b',
		},
	},
	'segments': {
		'left': [
			{
				'type': 'string',
				'name': 's',
				'contents': 't',
				'highlight_group': ['g'],
			},
		],
		'right': [],
	}
}


main_tree = lambda: {
	'1/config': root_config(),
	'1/colors': colors_config(),
	'1/colorschemes/default': colorscheme_config(),
	'1/themes/test/default': theme_config(),
}


def mkdir_recursive(directory):
	if os.path.isdir(directory):
		return
	mkdir_recursive(os.path.dirname(directory))
	os.mkdir(directory)


class TestPowerline(Powerline):
	def get_config_paths(self):
		return tuple(sorted([
			os.path.join(CONFIG_DIR, d)
			for d in os.listdir(CONFIG_DIR)
		]))


class WithConfigTree(object):
	__slots__ = ('tree', 'p', 'p_kwargs')

	def __init__(self, tree, p_kwargs={'run_once': True}):
		self.tree = tree
		self.p = None
		self.p_kwargs = p_kwargs

	def __enter__(self, *args):
		os.mkdir(CONFIG_DIR)
		for k, v in self.tree.items():
			fname = os.path.join(CONFIG_DIR, k) + '.json'
			mkdir_recursive(os.path.dirname(fname))
			with open(fname, 'w') as F:
				json.dump(v, F)
		select_renderer(simpler_renderer=True)
		self.p = TestPowerline(
			ext='test',
			renderer_module='tests.lib.config_mock',
			**self.p_kwargs
		)
		if os.environ.get('POWERLINE_RUN_LINT_DURING_TESTS'):
			try:
				check_call(['scripts/powerline-lint'] + reduce(add, (
					['-p', d] for d in self.p.get_config_paths()
				)))
			except:
				self.__exit__()
				raise
		return self.p.__enter__(*args)

	def __exit__(self, *args):
		try:
			rmtree(CONFIG_DIR)
		finally:
			if self.p:
				self.p.__exit__(*args)


class TestMerging(TestCase):
	def assertRenderEqual(self, p, output, **kwargs):
		self.assertEqual(p.render(**kwargs).replace(' ', ' '), output)

	def test_not_merged_config(self):
		with WithConfigTree(main_tree()) as p:
			self.assertRenderEqual(p, '{12} bt{2-}#>{--}')

	def test_root_config_merging(self):
		with WithConfigTree(mdc(main_tree(), {
			'2/config': {
				'common': {
					'dividers': {
						'left': {
							'hard': '!>',
						}
					}
				}
			},
		})) as p:
			self.assertRenderEqual(p, '{12} bt{2-}!>{--}')
		with WithConfigTree(mdc(main_tree(), {
			'2/config': {
				'common': {
					'dividers': {
						'left': {
							'hard': '!>',
						}
					}
				}
			},
			'3/config': {
				'common': {
					'dividers': {
						'left': {
							'hard': '>>',
						}
					}
				}
			},
		})) as p:
			self.assertRenderEqual(p, '{12} bt{2-}>>{--}')
		with WithConfigTree(mdc(main_tree(), {
			'2/config': {
				'common': {
					'spaces': 1,
				}
			},
			'3/config': {
				'common': {
					'dividers': {
						'left': {
							'hard': '>>',
						}
					}
				}
			},
		})) as p:
			self.assertRenderEqual(p, '{12} bt {2-}>>{--}')

	def test_colors_config_merging(self):
		with WithConfigTree(mdc(main_tree(), {
			'2/colors': {
				'colors': {
					'c1': 3,
				}
			},
		})) as p:
			self.assertRenderEqual(p, '{32} bt{2-}#>{--}')
		with WithConfigTree(mdc(main_tree(), {
			'2/colors': {
				'colors': {
					'c1': 3,
				}
			},
			'3/colors': {
				'colors': {
					'c1': 4,
				}
			},
		})) as p:
			self.assertRenderEqual(p, '{42} bt{2-}#>{--}')
		with WithConfigTree(mdc(main_tree(), {
			'2/colors': {
				'colors': {
					'c1': 3,
				}
			},
			'3/colors': {
				'colors': {
					'c2': 4,
				}
			},
		})) as p:
			self.assertRenderEqual(p, '{34} bt{4-}#>{--}')

	def test_colorschemes_merging(self):
		with WithConfigTree(mdc(main_tree(), {
			'2/colorschemes/default': {
				'groups': {
					'g': {'fg': 'c2', 'bg': 'c1', 'attr': []},
				}
			},
		})) as p:
			self.assertRenderEqual(p, '{21} bt{1-}#>{--}')

	def test_theme_merging(self):
		with WithConfigTree(mdc(main_tree(), {
			'2/themes/test/default': {
				'segment_data': {
					's': {
						'after': 'a',
					}
				}
			},
		})) as p:
			self.assertRenderEqual(p, '{12} bta{2-}#>{--}')


if __name__ == '__main__':
	from tests import main
	main()