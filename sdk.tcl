

exec mkdir /home/arthur/Documents/cdo2/workspace_sdk
setws /home/arthur/Documents/cdo2/workspace_sdk
cd workspace_sdk

#criar um projeto da plataforma
createhw -name platform_ov7670 -hwspec ../ov7670/ov7670.sdk/platform_wrapper.hdf


createapp -name app_camera -bsp bsp_camera -hwproject platform_ov7670 -proc ps7_cortexa9_0

# configura entrada uart para uart_1
configbsp -bsp bsp_camera stdin "ps7_uart_1"
configbsp -bsp bsp_camera stdout "ps7_uart_1"
updatemss -mss ./bsp_camera/system.mss
regenbsp -bsp bsp_camera


importsources -name app_camera -path ../fmwa


