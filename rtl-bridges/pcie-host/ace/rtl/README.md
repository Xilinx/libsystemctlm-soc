# ACE Master and Slave Bridge RTL

## ACE Master
ACE Master top modules ( ACE-Full ) are parameterized to support various values. ( i.e M_ACE_USR_ID_WIDTH, M_ACE_USR_DATA_WIDTH )

Following are the list of Parameter and values which are Supported and Tested with ACE Master

|Parameter                        | Values Supported  | Values Tested   |
|---------------------------------|-------------------|-----------------|
|S_ACE_ADDR_WIDTH              	  |   32,64	      |	64              |
|S_ACE_DATA_WIDTH              	  |   32              | 32              |
|M_ACE_ADDR_WIDTH              	  |   Upto 64         | 64              |
|M_ACE_DATA_WIDTH              	  |   128             | 128             |
|M_ACE_ID_WIDTH                	  |   log2(MAX_DESC)  | 4               |
|M_ACE_USER_WIDTH              	  |   1-32            | 32              |
|M_ACE_USR_ADDR_WIDTH          	  |   Upto 64         | 64              |
|M_ACE_USR_DATA_WIDTH          	  |   128             | 128             |
|M_ACE_USR_ID_WIDTH            	  |   1-16            | 16              |
|M_ACE_USR_AWUSER_WIDTH        	  |   1-32            | 32              |
|M_ACE_USR_WUSER_WIDTH         	  |   1-32            | 32              |
|M_ACE_USR_BUSER_WIDTH         	  |   1-32            | 32              |
|M_ACE_USR_ARUSER_WIDTH        	  |   1-32            | 32              |
|M_ACE_USR_RUSER_WIDTH         	  |   1-32            | 32              |
|RAM_SIZE                      	  |   16384           | 16384           |
|MAX_DESC                      	  |   1-16            | 16              |
|USR_RST_NUM                   	  |   1-31            | 4               |
|EXTEND_WSTRB                  	  |   0-1             | 1               |
|CACHE_LINE_SIZE              	  |   64              | 64              |


## ACE Slave
ACE Slave top modules ( ACE-Full ) are parameterized to support various Values. i.e S_ACE_USR_ID_WIDTH, S_ACE_USR_DATA_WIDTH.

Following are the list of Parameter and values which are Supported and Tested with ACE Slave

|Parameter                        | Values Supported  | Values Tested   |
|---------------------------------|-------------------|-----------------|
|S_ACE_ADDR_WIDTH              	  |   32,64	      |	64              |
|S_ACE_DATA_WIDTH              	  |   32              | 32              |
|M_ACE_ADDR_WIDTH              	  |   Upto 64         | 64              |
|M_ACE_DATA_WIDTH              	  |   128             | 128             |
|M_ACE_ID_WIDTH                	  |   log2(MAX_DESC)  | 4               |
|M_ACE_USER_WIDTH              	  |   1-32            | 32              |
|S_ACE_USR_ADDR_WIDTH          	  |   Upto 64         | 64              |
|S_ACE_USR_DATA_WIDTH          	  |   128             | 128             |
|S_ACE_USR_ID_WIDTH            	  |   1-16            | 16              |
|S_ACE_USR_AWUSER_WIDTH        	  |   1-32            | 32              |
|S_ACE_USR_WUSER_WIDTH         	  |   1-32            | 32              |
|S_ACE_USR_BUSER_WIDTH         	  |   1-32            | 32              |
|S_ACE_USR_ARUSER_WIDTH        	  |   1-32            | 32              |
|S_ACE_USR_RUSER_WIDTH         	  |   1-32            | 32              |
|RAM_SIZE                      	  |   16384           | 16384           |
|MAX_DESC                      	  |   1-16            | 16              |
|USR_RST_NUM                   	  |   1-31            | 4               |
|EXTEND_WSTRB                  	  |   0-1             | 1               |
|CACHE_LINE_SIZE              	  |   64              | 64              |


