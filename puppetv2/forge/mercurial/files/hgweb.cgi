#!/usr/bin/python

# enable importing on demand to reduce startup time
from mercurial import demandimport; demandimport.enable()

import os
os.environ["HGENCODING"] = "UTF-8"

from mercurial.hgweb.hgwebdir_mod import hgwebdir
import mercurial.hgweb.wsgicgi as wsgicgi

application = hgwebdir('hgweb.config')
wsgicgi.launch(application)