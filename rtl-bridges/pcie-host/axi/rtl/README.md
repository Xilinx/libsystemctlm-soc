# AXI Master and Slave Bridge RTL

## AXI Master
AXI Master top modules ( AXI4, AXI3, AXI4-Lite ) are parameterized to support various values. ( i.e M_AXI_USR_ID_WIDTH, M_AXI_USR_DATA_WIDTH )

Following are the list of Parameter and values which are Supported and Tested with AXI Master

|Parameter                        | Values Supported  | Values Tested   |
|---------------------------------|-------------------|-----------------|
|S_AXI_ADDR_WIDTH              	  |   32,64	      |	64              |
|S_AXI_DATA_WIDTH              	  |   32              | 32              |
|M_AXI_ADDR_WIDTH              	  |   Upto 64         | 64              |
|M_AXI_DATA_WIDTH              	  |   128             | 128             |
|M_AXI_ID_WIDTH                	  |   log2(MAX_DESC)  | 4               |
|M_AXI_USER_WIDTH              	  |   1-32            | 32              |
|M_AXI_USR_ADDR_WIDTH          	  |   Upto 64         | 64              |
|M_AXI_USR_DATA_WIDTH          	  |   32,64,128       | 32,64,128       |
|M_AXI_USR_ID_WIDTH            	  |   1-16            | 16              |
|M_AXI_USR_AWUSER_WIDTH        	  |   1-32            | 32              |
|M_AXI_USR_WUSER_WIDTH         	  |   1-32            | 32              |
|M_AXI_USR_BUSER_WIDTH         	  |   1-32            | 32              |
|M_AXI_USR_ARUSER_WIDTH        	  |   1-32            | 32              |
|M_AXI_USR_RUSER_WIDTH         	  |   1-32            | 32              |
|RAM_SIZE                      	  |   16384           | 16384           |
|MAX_DESC                      	  |   1-16            | 16              |
|USR_RST_NUM                   	  |   1-31            | 4               |
|EXTEND_WSTRB                  	  |   0-1             | 1               |


## AXI Slave
AXI Slave top modules ( AXI4,AXI3,AXI4-Lite ) are parameterized to support various Values. i.e S_AXI_USR_ID_WIDTH, S_AXI_USR_DATA_WIDTH.

Following are the list of Parameter and values which are Supported and Tested with AXI Slave

|Parameter                        | Values Supported  | Values Tested   |
|---------------------------------|-------------------|-----------------|
|S_AXI_ADDR_WIDTH              	  |   32,64	      |	64              |
|S_AXI_DATA_WIDTH              	  |   32              | 32              |
|M_AXI_ADDR_WIDTH              	  |   Upto 64         | 64              |
|M_AXI_DATA_WIDTH              	  |   128             | 128             |
|M_AXI_ID_WIDTH                	  |   log2(MAX_DESC)  | 4               |
|M_AXI_USER_WIDTH              	  |   1-32            | 32              |
|S_AXI_USR_ADDR_WIDTH          	  |   Upto 64         | 64              |
|S_AXI_USR_DATA_WIDTH          	  |   32,64,128       | 32,64,128       |
|S_AXI_USR_ID_WIDTH            	  |   1-16            | 16              |
|S_AXI_USR_AWUSER_WIDTH        	  |   1-32            | 32              |
|S_AXI_USR_WUSER_WIDTH         	  |   1-32            | 32              |
|S_AXI_USR_BUSER_WIDTH         	  |   1-32            | 32              |
|S_AXI_USR_ARUSER_WIDTH        	  |   1-32            | 32              |
|S_AXI_USR_RUSER_WIDTH         	  |   1-32            | 32              |
|RAM_SIZE                      	  |   16384           | 16384           |
|MAX_DESC                      	  |   1-16            | 16              |
|USR_RST_NUM                   	  |   1-31            | 4               |
|EXTEND_WSTRB                  	  |   0-1             | 1               |

