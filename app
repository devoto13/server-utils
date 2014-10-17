#!/usr/bin/env python

# if [ -z $1 ]; then
#     echo 'Please, supply application name.'
#     exit 1
# fi

# app=/web/apps/$1

# if [ -d "$app" ]; then
#     echo 'Application already exists.'
#     exit 2
# fi

# mkdir -p $app/repo && cd $app/repo && git init --bare > /dev/null && ln -s /web/utils/utils/post-receive hooks/post-receive
# mkdir -p $app/app && cd $app/app && git init > /dev/null &&  git remote add origin ../repo > /dev/null
# touch $app/fig.yml

# echo "Application successfully created. Next steps:"
# echo "  1. Edit $app/fig.yml to configure server setup."
# echo "  2. Add config for ngingx."
# echo "  3. Push code into repository."
