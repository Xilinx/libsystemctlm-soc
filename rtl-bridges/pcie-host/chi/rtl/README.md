# CHI RN_F and HN_F Bridge RTL

CHI Bridge top modules, CHI RN_F and CHI HN_F are parameterized to support various values.

Following are the list of Parameter and values which are Supported and Tested with CHI RN_F and CHI HN_F Bridge.

|Parameter                        | Values Supported  | Values Tested   |
|---------------------------------|-------------------|-----------------|
|S_AXI_ADDR_WIDTH              	  |   32,64	      |	32              |
|S_AXI_DATA_WIDTH              	  |   32              | 32              |
|CHI_VERSION           		  |   0-Ver.B,1-Ver.C | 0             |
|CHI_NODE_ID_WIDTH             	  |   7 to 11             | 7            |
|CHI_REQ_ADDR_WIDTH           	  |   45 to 52 |       48       |
|CHI_FLIT_DATA_WIDTH           	  | 128,256,512        | 512              |
|CHI_DMT_ENA         	 	  |   0,1         | 1           |
|CHI_DCT_ENA          		  |   0,1       | 1      |
|CHI_ATOMIC_ENA           	  |   0,1        | 1              |
|CHI_STASHING_ENA        	  |   0,1          | 0            |
|CHI_DATA_POISON_ENA         	  |   0,1            | 0             |
|CHI_DATA_CHECK_ENA         	  |   0,1            | 0             |
|CHI_CCF_WRAP_ORDER      	  |   0,1           | 0              |
|CHI_ENHANCE_FEATURE_EN        	  |   0,1            | 0             |
|USR_RST_NUM                      | 1 to 4              | 4            |
|LAST_BRIDGE                      |   0 to 1            | 0              |



