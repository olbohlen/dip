#!/bin/ksh
# olbohlen 2016-11-17
# dumb ips pre-package-installer

builtdir="$1/"

pmfile="$2"

rootpath="$3/"

export rootpath pmfile builtdir

sed -e ':a' -e 'N' -e '$!ba' -e 's/\\\n/ /g' ${pmfile} | nawk '
$1~/^(file|dir|link|hardlink)$/
BEGIN {
  printf("#foo\n") > "/tmp/files.out";
  printf("#foo\n") > "/tmp/dirs.out";
  printf("#foo\n") > "/tmp/links.out";
  printf("#foo\n") > "/tmp/hardlinks.out";
}
{
  if($1~/^dir$/) {
    path=substr($0, match($0, " path=[^ ]*"), RLENGTH);
    owner=substr($0, match($0, " owner=[^ ]*"), RLENGTH);
    group=substr($0, match($0, " group=[^ ]*"), RLENGTH);
    mode=substr($0, match($0, " mode=[^ ]*"), RLENGTH);
    
    sub("[a-z]*=", "", path);
    sub("[a-z]*=", "", owner);
    sub("[a-z]*=", "", group);
    sub("[a-z]*=", "", mode);

    gsub(" ", "", group);
    gsub(" ", "", owner);
    gsub(" ", "", mode);
    sub("^0", "", mode);

    sub("^ ", ENVIRON["rootpath"], path);
    printf("mkdir %s\nchown %s:%s %s\nchmod %s %s\n", path, owner, group, path, mode, path) >> "/tmp/dirs.out";
  }
  if($1~/^file$/) {
    srcpath=$2;
    path=substr($0, match($0, " path=[^ ]*"), RLENGTH);
    owner=substr($0, match($0, " owner=[^ ]*"), RLENGTH);
    group=substr($0, match($0, " group=[^ ]*"), RLENGTH);
    mode=substr($0, match($0, " mode=[^ ]*"), RLENGTH);
    
    sub("[a-z]*=", "", path);
    sub("[a-z]*=", "", owner);
    sub("[a-z]*=", "", group);
    sub("[a-z]*=", "", mode);

    gsub(" ", "", group);
    gsub(" ", "", owner);
    gsub(" ", "", mode);
    sub("^0", "", mode);

    sub("^ ", ENVIRON["rootpath"], path);
    sub("^", ENVIRON["builtdir"], srcpath);
    printf("cp %s %s\nchown %s:%s %s\nchmod %s %s\n", srcpath, path, owner, group, path, mode, path) >> "/tmp/files.out";
  }
  if($1~/^link$/) {
    path=substr($0, match($0, " path=[^ ]*"), RLENGTH);
    target=substr($0, match($0, " target=[^ ]*"), RLENGTH);
    
    sub("[a-z]*=", "", path);
    sub("[a-z]*=", "", target);
    sub("^ ", "", target);
    sub("^ ", ENVIRON["rootpath"], path);
    e=split(path,a,"/")
    for(i=1;i<e;i++) {
      dirname=sprintf("%s%s/", dirname,a[i]);
    }
    printf("(cd %s && ln -s %s%s %s)\n", ENVIRON["rootpath"], dirname, target, path) >> "/tmp/links.out";
    dirname="";
  }
  if($1~/^hardlink$/) {
    path=substr($0, match($0, " path=[^ ]*"), RLENGTH);
    target=substr($0, match($0, " target=[^ ]*"), RLENGTH);
    
    sub("[a-z]*=", "", path);
    sub("[a-z]*=", "", target);
    sub("^ ", "", target);
    sub("^ ", ENVIRON["rootpath"], path);
    e=split(path,a,"/")
    for(i=1;i<e;i++) {
      dirname=sprintf("%s%s/", dirname,a[i]);
    }
    printf("(cd %s && ln %s%s %s)\n", ENVIRON["rootpath"], dirname, target, path) >> "/tmp/hardlinks.out";
    dirname="";
  }

  printf("# %s\n", $0);


}
'

