
exec mkdir /home/arthur/Documents/cod/workspace_sdk
setws /home/arthur/Documents/cod/workspace_sdk
cd workspace_sdk

#criar um projeto da plataforma
createhw -name platform_ov7670 -hwspec ../ov7670/ov7670.sdk/platform_wrapper.hdf
#bsp um projeto da plataforma
createbsp -name bsp_ov7670 -hwproject platform_ov7670 -proc ps7_cortexa9_0

# configura entrada uart para uart_1
configbsp -bsp bsp_ov7670 stdin "ps7_uart_1"
configbsp -bsp bsp_ov7670 stdout "ps7_uart_1"


#criar um projeto de aplicacao
createapp -name app_camera -bsp bsp_ov7670 -hwproject platform_ov7670 -proc ps7_cortexa9_0




