import mongoose from "mongoose";

const connectDB = async () => {
  const maxRetries = 10;
  let retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      await mongoose.connect(process.env.MONGO_URI);
      console.log("Successfully connected to MongoDB 👍");
      return;
    } catch (error) {
      retryCount++;
      console.error(
        `MongoDB connection attempt ${retryCount}/${maxRetries} failed: ${error.message}`
      );

      if (retryCount < maxRetries) {
        console.log("Retrying MongoDB connection in 5 seconds...");
        await new Promise((resolve) => setTimeout(resolve, 5000));
      } else {
        console.error("MongoDB connection failed after maximum retries.");
        process.exit(1);
      }
    }
  }
};

export default connectDB;
