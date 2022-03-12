APP = syzygy-ecm1900

# Add any other object files to this list below
APP_OBJS = syzygy-ecm1900.o syzygy.o

all: build

build: $(APP)

$(APP): $(APP_OBJS)
	$(CXX) -o $@ $(APP_OBJS) $(LDFLAGS) $(LDLIBS)
clean:
	rm -f $(APP) *.o
