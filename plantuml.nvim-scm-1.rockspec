rockspec_format = '3.0'
package = 'plantuml.nvim'
version = 'scm-1'
source = {
  url = 'git@github.com:goropikari/plantuml.nvim.git',
}
description = {
  summary = 'example hello module',
  detailed = [[example hello module]],
  homepage = 'https://github.com/goropikari/plantuml.nvim',
  license = 'MIT',
  maintainer = 'goropikari',
}
dependencies = {
  'lua >= 5.1',
  'LibDeflate',
}
test_dependencies = {}
build = {
  type = 'builtin',
  copy_directories = {},
}
