APP = set-clock-brk1900

# Add any other object files to this list below
APP_OBJS = set-clock-brk1900.o

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CXX) -o $@ $(APP_OBJS) $(LDFLAGS) $(LDLIBS)
clean:
	rm -f $(APP) *.o
