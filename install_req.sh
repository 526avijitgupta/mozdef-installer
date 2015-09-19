echo "abc"
MOZ_PATH=/opt/MozDef
echo $MOZ_PATH
PATH_TO_VENV=$HOME/.mozdef_env

. $PATH_TO_VENV/bin/activate

pip install -r $MOZ_PATH/requirements.txt
