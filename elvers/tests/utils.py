import tempfile
import shutil
import yaml

from .const import here
from subprocess import Popen, PIPE

def capture_stdouterr(command, cwd = here):
    p = Popen(command, cwd=cwd, stdout=PIPE, stderr=PIPE).communicate()
    p_out = p[0].decode('utf-8').strip()
    p_err = p[1].decode('utf-8').strip()
    return (p_out, p_err)

def write_yaml(yamlD, paramsfile):
    with open(paramsfile, 'w') as params:
        yaml.dump(yamlD, stream=params, indent=2,  default_flow_style=False)

class TempDirectory(object):
    def __init__(self):
        self.tempdir = tempfile.mkdtemp(prefix='elverstest_')

    def __enter__(self):
        return self.tempdir

    def __exit__(self, exc_type, exc_value, traceback):
        try:
            shutil.rmtree(self.tempdir, ignore_errors=True)
        except OSError:
            pass

        if exc_type:
            return False
