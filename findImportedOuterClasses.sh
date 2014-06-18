#!/bin/bash

SOURCE_DIR=$1
TEMP_DIR="/tmp/servicemonitor2"
M2_REPO="$HOME/.m2/repository"

CLASS_FILTER="xiaonei|renren"
ALL_LOCAL_JAVA_CLASSES_FILE="$TEMP_DIR/all_local_java_classes.tmp"
ALL_LOCAL_JAVA_PACKAGES="$TEMP_DIR/all_local_java_pacakges.tmp"
ALL_IMPORTED_CLASSES="$TEMP_DIR/all_imported_classes.tmp"
ALL_IMPORTED_CLASSES_UNSORT="$TEMP_DIR/all_imported_classes_unsort.tmp"
ALL_RENREN_JAR="$TEMP_DIR/all_renren_jar.tmp"
ALL_RENREN_CLASSES="$TEMP_DIR/all_renren_classes.tmp"
ALL_RENREN_JAR_CLASSES="$TEMP_DIR/all_renren_jar_classes.tmp"

ASTERISK_OUTER_CLASSES_RESULT="$TEMP_DIR/asterisk_outer_classes_result.tmp"
ASTERISK_IMPORT_OUTER_PACKAGE="$TEMP_DIR/asterisk_imported_outer_package.tmp"
ASTERISK_IMPORT_PACKAGE="$TEMP_DIR/asterisk_imported_package.tmp"

OUTER_CLASSES_RESULT="$TEMP_DIR/outer_classes_result.tmp"
OUT_CLASSES_JAR_MAPPING="$TEMP_DIR/outer_classes_jar_mapping.tmp"

rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

echo "Extract all local Java Class name and imported Class name.............."
#抽取本地project所有的Java类名;  抽取本地Java类所有import的类名; 处理import static, 将static引用的最后一个.[^.]删除后就是类名
(cd $SOURCE_DIR; find . -name '*.java' | sed 's/\.\/src\/main\/java\///; s/.java//; s/\//./g' | sort > $ALL_LOCAL_JAVA_CLASSES_FILE; find . -name '*.java' -print0 | xargs -0 sed -nr "/^import.*($CLASS_FILTER)/p;" | sed 's/^import *//; s/;//; /^static/s/\.[^.]*$//; s/^static *//' | tr -d '\r' > $ALL_IMPORTED_CLASSES_UNSORT)

echo "Extract all outer jar's Class name....................................."
(cd $SOURCE_DIR; sed -rn "/($CLASS_FILTER)/p" .classpath | sed "s%.*\(/com/[$CLASS_FILTER].*\.jar\).*%\1%" | grep '^/com' > "$ALL_RENREN_JAR")
cd $M2_REPO
allrenrenjars=`cat $ALL_RENREN_JAR`
for jarname in $allrenrenjars
   do
      jar -tvf $M2_REPO""$jarname | awk -v var=$jarname '{print var" "$8}' | sed -n "/\.class/p" >> $ALL_RENREN_JAR_CLASSES
   done
awk '{print $2}' $ALL_RENREN_JAR_CLASSES | sed 's/\//\./g' | sort | uniq > $ALL_RENREN_CLASSES

echo "Extract import .*   ..................................................."
#处理import *
(cd $TEMP_DIR; sed -n "/\.\*$/w $ASTERISK_IMPORT_PACKAGE" $ALL_IMPORTED_CLASSES_UNSORT; sed -i "/\.\*$/d" $ALL_IMPORTED_CLASSES_UNSORT)

if [ -s $ASTERISK_IMPORT_PACKAGE ]; then

    echo "Extract all local Java Pacakge name...................................."
#抽取出本地所有的Java包名,比较import .*是不是都是本地的包名,如果是就不用处理,如果不是,就要去所所依赖的Jar包中找到.*所代表的所有类名    
    (cd $SOURCE_DIR; find ./src/main/java/ -type d | sed 's/\.\/src\/main\/java\///; s/\//\./g' | sort | uniq > $ALL_LOCAL_JAVA_PACKAGES; cd $TEMP_DIR; sort $ASTERISK_IMPORT_PACKAGE | uniq | sed "s/\.\*$//" | comm -23 - $ALL_LOCAL_JAVA_PACKAGES > $ASTERISK_IMPORT_OUTER_PACKAGE )
    
#在当前project的.classpath文件里面找到所有依赖的xiaonei, renren的jar,解压,找到import .*引入的所有引用类名
    if [ -s $ASTERISK_IMPORT_OUTER_PACKAGE ]; then
#根据引用的外部包名把包下面所有的Class名找出来
        outerpackages=`cat $ASTERISK_IMPORT_OUTER_PACKAGE`
        for package in $outerpackages
        do
           grep "^$package\.[^\.]*\.class$" $ALL_RENREN_CLASSES | sed 's/\.class$//; s/\$.*$//' >> $ASTERISK_OUTER_CLASSES_RESULT
        done
        cat $ASTERISK_OUTER_CLASSES_RESULT >> $ALL_IMPORTED_CLASSES_UNSORT
        cd $SOURCE_DIR
    fi
fi

sort $ALL_IMPORTED_CLASSES_UNSORT | uniq > $ALL_IMPORTED_CLASSES
rm $ALL_IMPORTED_CLASSES_UNSORT

echo "Generating all outer Class name file..................................."
comm -23 $ALL_IMPORTED_CLASSES $ALL_LOCAL_JAVA_CLASSES_FILE > $OUTER_CLASSES_RESULT

# 最后过滤对本地Java类的内部类的import引用
localclasses=`cat $ALL_LOCAL_JAVA_CLASSES_FILE`
for localclass in $localclasses
do
    sed -i "/^${localclass}\.[^\.]*$/d" $OUTER_CLASSES_RESULT 
done

echo "Generating out class to jar file mapping..............................."
cp $OUTER_CLASSES_RESULT $OUTER_CLASSES_RESULT"1"

sed -i "s/\./\//g" $OUTER_CLASSES_RESULT"1"

outclasses=`cat $OUTER_CLASSES_RESULT"1"`
for outclass in $outclasses
do
    grep "${outclass}\.class" $ALL_RENREN_JAR_CLASSES >> $OUT_CLASSES_JAR_MAPPING
done

#awk '{print $1}' $OUT_CLASSES_JAR_MAPPING"1" > $TEMP_DIR/onlyjar.tmp
#awk '{print $2}' $OUT_CLASSES_JAR_MAPPING"1" | sed 's/\//\./g' > $TEMP_DIR/onlyclass.tmp
#paste -d' ' $TEMP_DIR/onlyclass.tmp $TEMP_DIR/onlyjar.tmp >> $OUT_CLASSES_JAR_MAPPING 
rm $OUTER_CLASSES_RESULT"1"
#rm $OUT_CLASSES_JAR_MAPPING"1"
#rm $TEMP_DIR/onlyjar.tmp
#rm $TEMP_DIR/onlyclass.tmp





