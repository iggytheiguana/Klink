//
//  Macros.h
//  Platform
//
//  Created by Bobby Gill on 10/17/11.
//  Copyright 2011 Blue Label Solutions LLC. All rights reserved.
//

#ifdef DEBUG
#define LOG_SECURITY(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"security",level,__VA_ARGS__)
#define LOG_REQUEST(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"request",level,__VA_ARGS__)
#define LOG_RESOURCE(level, ...)   LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"resource",level,__VA_ARGS__)
#define LOG_RESOURCECONTEXT(level, ...)   LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"resourcecontext",level,__VA_ARGS__)
#define LOG_HTTP(level, ...)   LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"http",level,__VA_ARGS__)
#define LOG_CONFIGURATION(level, ...)   LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"configuration",level,__VA_ARGS__)
#define LOG_ENUMERATION(level, ...)   LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"enumeration",level,__VA_ARGS__)
#else
#define LOG_NETWORK(...)    do{}while(0)
#define LOG_GENERAL(...)    do{}while(0)
#define LOG_GRAPHICS(...)   do{}while(0)
#endif
