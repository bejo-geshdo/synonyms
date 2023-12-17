import express from "express";

import addRoutes from "./routes/add";
import searchRoutes from "./routes/find";

const app = express();
const port = process.env.PORT || 8080;

app.use(express.json());

app.use("/add", addRoutes);

app.use("/find", searchRoutes);

//Starts the express js server on port
const server = app.listen(port, () => {
  console.log(`App running at http://localhost:${port}`);
});

//Graceful termination of express
process.on("SIGTERM", () => {
  console.log("SIGTERM signal received: closing HTTP server");
  server.close(() => {
    console.log("HTTP server closed");
    process.exit(0);
  });
});

//TODO Look into adding http-terminator
