okFP_SDK ?= ../../../API

CXXFLAGS := -Isrc -I$(okFP_SDK) -Iinclude -std=c++11 -Wall -Wpedantic -g
LDFLAGS := -L$(okFP_SDK)

LIBS := -ldl -lsndfile -lm
okFP_LIBS := -lokFrontPanel

CXX = g++

VPATH = src

.SUFFIXES:
.SUFFIXES: .cpp .o

AudioPipe: AudioPipe.o AudioFile.o
	$(CXX) $(okFP_LDFLAGS) $(LDFLAGS) $(CXXFLAGS) -o $@ $^ $(okFP_LIBS) $(LIBS)

AudioFile.o: include/AudioFile.h

AudioPipe.o: AudioPipe.cpp include/AudioFile.h
	$(CXX) $(CXXFLAGS) -c $<
