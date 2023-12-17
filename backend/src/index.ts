import express from "express";

import addRoutes from "./routes/add";
const app = express();
const port = process.env.PORT || 8080;

app.use(express.json());

app.use("/add", addRoutes);

//Starts the express js server on port
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
