/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

/*
 * vdmaTest.c
 *
 *  Created on: Apr 9, 2020
 *      Author: VIPIN
 */
#include "xparameters.h"
#include  "camera.h"
#include "xscugic.h"
#include "sleep.h"
#include "xaxivdma.h"
#include <stdlib.h>
#include "xil_cache.h"
#include "platform.h"
#include "xil_io.h"
#include "xstatus.h"
#include "xil_exception.h"

#define SIZE_ARR 640*480
#define PWM_BASE_ADDRESS               0x43C00000
#define HSize 640
#define VSize 480
#define FrameSize HSize*VSize*4


static XScuGic Intc;


//static int SetupIntrSystem(XAxiVdma *AxiVdmaPtr, u16 ReadIntrId);
u32 Buffer[FrameSize];

u8 final_image[240][320];
XAxiVdma myVDMA;


u32 sta;
u32 *address_bram = (u32 *)INIT_CONFIG ;


/************************** Variable Definitions *****************************/

/*
 * The following are declared globally so they are zeroed and so they are
 * easily accessible from a debugger
 */

/* LED brightness level is now global to make is visble to the ISR. */
volatile u32 contador = 0;
/* The Instance of the Interrupt Controller Driver */


/*****************************************************************************/
 /* Call back function for read channel
******************************************************************************/

static void WriteCallBack(void *CallbackRef, u32 Mask)
{
	XAxiVdma_DmaStop(&myVDMA,XAXIVDMA_WRITE);
	// passa a imagem pela interface UART- leitura matlab
	// Nao deveria fazer isso dentro de introut, so para mostrar a imagem,
	for (int i = 0; i < 480; i++) {
		for (int j = 0; j < 640; j++) {
		printf("%d\n",  Buffer[j+640*i]);


		}
	}
	XAxiVdma_DmaStart(&myVDMA,XAXIVDMA_WRITE);

contador++;
}

/*****************************************************************************/
/*
 * The user can put his code that should get executed when this
 * call back happens.
 *
*
******************************************************************************/
static void WriteErrorCallBack(void *CallbackRef, u32 Mask)
{
	/* User can add his code in this call back function */
	printf("Read Call back Error function is called\r\n");

}
static int SetupIntrSystem(XAxiVdma *AxiVdmaPtr, u16 WriteIntrId)
{
	int Status;
	XScuGic *IntcInstancePtr =&Intc;

	/* Initialize the interrupt controller and connect the ISRs */
	XScuGic_Config *IntcConfig;
	IntcConfig = XScuGic_LookupConfig(XPAR_PS7_SCUGIC_0_DEVICE_ID);
	Status =  XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
	if(Status != XST_SUCCESS){
		xil_printf("Interrupt controller initialization failed..");
		return -1;
	}

	Status = XScuGic_Connect(IntcInstancePtr,WriteIntrId,(Xil_InterruptHandler)XAxiVdma_WriteIntrHandler,(void *)AxiVdmaPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed read channel connect intc %d\r\n", Status);
		return XST_FAILURE;
	}

	XScuGic_Enable(IntcInstancePtr,WriteIntrId);

	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,(Xil_ExceptionHandler)XScuGic_InterruptHandler,(void *)IntcInstancePtr);
	Xil_ExceptionEnable();

	/* Register call-back functions
	 */
	XAxiVdma_SetCallBack(AxiVdmaPtr, XAXIVDMA_HANDLER_GENERAL, WriteCallBack, (void *)AxiVdmaPtr, XAXIVDMA_WRITE);

	XAxiVdma_SetCallBack(AxiVdmaPtr, XAXIVDMA_HANDLER_ERROR, WriteErrorCallBack, (void *)AxiVdmaPtr, XAXIVDMA_WRITE);

	return XST_SUCCESS;
}
//
//
//int SetupInterruptSystem()
//{
//	int result;
//
//
//
//
//	/* Initialize the interrupt controller driver so that it is ready to
//	 * use. */
//	IntcConfig = XScuGic_LookupConfig(XPAR_PS7_SCUGIC_0_DEVICE_ID);
//	if (IntcConfig == NULL)
//	{
//		return XST_FAILURE;
//	}
//
//	/* Initialize the SCU and GIC to enable the desired interrupt
//	 * configuration. */
//	result = XScuGic_CfgInitialize(&InstIntc, IntcConfig,
//					IntcConfig->CpuBaseAddress);
//	if (result != XST_SUCCESS)
//	{
//		return XST_FAILURE;
//	}
//
//	XScuGic_SetPriorityTriggerType(&InstIntc, INTC_INTERRUPT_ID, 0xA0, 3);
//
//	/* Connect the interrupt handler that will be called when an
//	 * interrupt occurs for the device. */
//	result = XScuGic_Connect(&InstIntc, INTC_INTERRUPT_ID,(Xil_ExceptionHandler)vsyncIsr, 0);
//	if (result != XST_SUCCESS)
//	{
//		return result;
//	}
//
//	/* Enable the interrupt for the PWM controller device. */
//	XScuGic_Enable(&InstIntc, INTC_INTERRUPT_ID);
//
//	/* Initialize the exception table and register the interrupt controller
//	 * handler with the exception table. */
//	Xil_ExceptionInit();
//	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, (void *)&InstIntc);
//
//	/* Enable non-critical exceptions */
//	Xil_ExceptionEnable();
//
//	return XST_SUCCESS;
//}

int SetupVdma(){
	int status;
		int Index;
		u32 Addr;

		XAxiVdma_Config *config = XAxiVdma_LookupConfig(XPAR_AXI_VDMA_0_DEVICE_ID);
		XAxiVdma_DmaSetup WriteCfg;

		status = XAxiVdma_CfgInitialize(&myVDMA, config, config->BaseAddress);
	    if(status != XST_SUCCESS){
	    	xil_printf("DMA Initialization failed");
	    }

	    WriteCfg.Stride = HSize*4;
	    WriteCfg.HoriSizeInput = HSize*4;
	    WriteCfg.VertSizeInput = VSize;
	    WriteCfg.FrameDelay = 0;
	    WriteCfg.EnableCircularBuf = 1;
	    WriteCfg.EnableSync = 1;
	    WriteCfg.PointNum = 0;
	    WriteCfg.EnableFrameCounter = 0;
	    WriteCfg.FixedFrameStoreAddr = 0;

	    status = XAxiVdma_DmaConfig(&myVDMA, XAXIVDMA_WRITE, &WriteCfg);
	    if (status != XST_SUCCESS) {
	    	xil_printf("Write channel config failed %d\r\n", status);
	    	return status;
	    }

	    Addr = (u32)&(Buffer[0]);


		for(Index = 0; Index < myVDMA.MaxNumFrames; Index++) {
			WriteCfg.FrameStoreStartAddr[Index] = Addr;
			Addr +=  FrameSize;
		}

		status = XAxiVdma_DmaSetBufferAddr(&myVDMA, XAXIVDMA_WRITE,WriteCfg.FrameStoreStartAddr);
		if (status != XST_SUCCESS) {
			if(status==XST_DEVICE_BUSY) xil_printf(" XST_DEVICE_BUSY Read channel set buffer address failed %d\r\n", status);
			if(status==XST_INVALID_PARAM) xil_printf(" XST_INVAID_PARAM Read channel set buffer address failed %d\r\n", status);
			if(status==XST_DEVICE_NOT_FOUND) xil_printf(" XST_DEVICE_NOT_FOUND Read channel set buffer address failed %d\r\n", status);
			return XST_FAILURE;
		}


		XAxiVdma_IntrDisable(&myVDMA, XAXIVDMA_IXR_COMPLETION_MASK, XAXIVDMA_WRITE);

		SetupIntrSystem(&myVDMA, XPAR_FABRIC_AXI_VDMA_0_S2MM_INTROUT_INTR);

		Xil_DCacheFlush();

		status = XAxiVdma_DmaStart(&myVDMA,XAXIVDMA_WRITE);
		if (status != XST_SUCCESS) {
			if(status == XST_VDMA_MISMATCH_ERROR)
				xil_printf("DMA Mismatch Error\r\n");
			return XST_FAILURE;
		}
}







union Data {
   u32 i;
   float f;
};


int main()
{
	union Data data;

	   u32 a;
	   u32 b;
	    float c;
	    float fps;
    init_platform();

    //Xil_Out32(IPSAMPLEALLOW,0);
    write_config_cam(); // escreve os valores destinados aos registradores da camera na BRAM


	config_cam(); //ativa o debounce ate a configuracao completar (add 2 segundos para que acomode estabilidade)

	pausar_imagem(); // ativa o stop e pausa imagem  no vsync '1'



	SetupVdma();
	sleep(10);

	XAxiVdma_IntrEnable(&myVDMA, XAXIVDMA_IXR_COMPLETION_MASK, XAXIVDMA_WRITE);






		// passa a imagem pela interface UART- leitura matlab
//		for (int i = 0; i < TIMG_HEIGTH; i++) {
//			for (int j = 0; j < TIMG_WIDTH; j++) {
//		printf("%d\n", (int)final_image[i][j]);
//
//			}
//		}




	while(1)
	{
		sleep(1);
		//printf("%d \n \r", contador);

	}


//	// passa a imagem pela interface UART- leitura matlab
//	for (int i = 0; i < TIMG_HEIGTH; i++) {
//		for (int j = 0; j < TIMG_WIDTH; j++) {
//		printf("%d\n", (int)final_image[i][j]);
//
//		}
//	}

    cleanup_platform();
    return 0;
}

