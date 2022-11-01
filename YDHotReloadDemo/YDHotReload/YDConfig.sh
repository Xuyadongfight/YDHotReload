config_path=$(find ${PROJECT_DIR} -name "hotreload_config")
#need_replace=$(grep project_path $config_path)
#new_replace="\"project_path\":\"${PROJECT_DIR}\","
need_replace="project_replace_path"
new_replace=${PROJECT_DIR}
echo $need_replace
echo $new_replace
res=$(sed "s#$need_replace#$new_replace#" $config_path)
echo $res
