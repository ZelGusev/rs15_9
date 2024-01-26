# сброс всех предустановелнных настроект и объявленных проектов загруженных файлов
remove_design -all
suppress_message UID-401
# назначение топ левела
set top "ew_ecc"
# применения настроек для design compiler библиотек и д.т.
source "./dc-compiler/scripts/dc_setup.tcl"
# чтение всех модулей
source "${script_path}read.tcl"
# выбор топ левела
current_design ${top}
# запусть топа
source "${script_path}${top}.tcl"
# в зависимости какой мод выбра shell_is_in_xg_mode - новый более продуктивный работает начиная с версии 2005 (ddc). в 2004 db мод
if { [shell_is_in_xg_mode] == 0 } {
write -hier -o "${db_path}${top}.db"
} else {
write -format ddc -hier -o "${ddc_path}${top}.ddc"}
# запись карты проекта
write_script > "${script_path}${top}.wtcl"
# сброс настроек
remove_design -all
# чтение всех модулей
source "${script_path}read.tcl"
# дефолт ограничения 
source "${script_path}defaults.tcl"
# чтение карты 
source "${script_path}${top}.wtcl"
# сборка
compile_ultra
# сохранение базы
if { [shell_is_in_xg_mode] == 0 } {
write -hier -o "${db_path}${top}_wtcl.db"
} else {
write -format ddc -hier -o "${ddc_path}${top}_wtcl.ddc" }
# репорт карты 
set rpt_file ${top}_wtcl.rpt
source "${script_path}report.tcl"