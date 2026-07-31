#ifndef SELECT_H
#define SELECT_H
/*=========================================================================*\
* Select implementation
* LuaSocket toolkit
*
* Each object that can be passed to the select function has to export 
* method getfd() which returns the descriptor to be passed to the
* underlying select function. Another method, dirty(), should return 
* true if there is data ready for reading (required for buffered input).
\*=========================================================================*/

int select_open(lua_State *L);

t_socket getfd(lua_State *L);
int dirty(lua_State *L);
void collect_fd(lua_State *L, int tab, int itab,
	fd_set *set, t_socket *max_fd);
int check_dirty(lua_State *L, int tab, int dtab, fd_set *set);
void return_fd(lua_State *L, fd_set *set, t_socket max_fd,
	int itab, int tab, int start);
void make_assoc(lua_State *L, int tab);

#endif /* SELECT_H */
