final: prev: {
  mongodb-no-avx = prev.mongodb.override {
    avxSupport = false;
  };
}
