import express, { Request, Response } from "express";

const app = express();
const port = process.env.PORT || 8080;

//Starts the express js server on port
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
