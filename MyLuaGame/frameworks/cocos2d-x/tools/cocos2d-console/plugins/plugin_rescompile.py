#!/usr/bin/python
# ----------------------------------------------------------------------------
# cocos2d "res compile" plugin
#
# ----------------------------------------------------------------------------
'''
"res compile" plugin for cocos2d command line tool
'''
from __future__ import print_function
from __future__ import unicode_literals

__docformat__ = 'restructuredtext'

import cocos

import os
import subprocess


class CCPluginResCompile(cocos.CCPlugin):
    """
    launches the cocos2d console gui
    """

    @staticmethod
    def plugin_name():
        return "rescompile"

    @staticmethod
    def brief_description():
        return "compile resource"

    def run(self, argv, dependencies):
        self._verbose = True

        # use tjpack/src_pack replace it. modify by huangwei 2018.8.23
        tjpack_path = os.getcwd()
        tjpack_path = tjpack_path[:tjpack_path.find("MyLuaGame")]
        tjpack_path = os.path.join(tjpack_path, "tools/tjpack")
        with cocos.pushd(tjpack_path):
            cmd_str = "python res_pack.py %s" % ' '.join(argv)
            self._run_cmd(cmd_str)
            self._run_cmd("type repo_mapping.json")






