import React, { useState } from "react";

const apiUrl = process.env.REACT_APP_API_URL || "http://localhost:8080";

function App() {
  const [word, setWord] = useState("");
  const [words, setWords] = useState([]);
  const [responseAdd, setResponseAdd] = useState("");
  const [response, setResponse] = useState("");

  const handleAddWord = () => {
    setWords((prevWords) => [...prevWords, word]);
    setWord("");
  };

  const handleAddToDB = async () => {
    if (words.length < 2) {
      setResponseAdd("You need at least two words");
      return;
    }
    try {
      const response = await fetch(`${apiUrl}/add`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ words }),
      });

      if (response.status === 201) {
        setResponseAdd("Success");
        setWords([]);
      } else {
        setResponseAdd("Error");
      }
    } catch (error) {
      console.error(error);
      setResponseAdd("Error");
    }
  };

  const handleFindWord = async () => {
    try {
      const response = await fetch(`${apiUrl}/find?word=${word}`);
      console.log("status: ", response.status);

      if (response.status === 200) {
        const data = await response.json();
        const words = data.message;
        setResponse(JSON.stringify(words));
      } else if (response.status === 404) {
        setResponse("Word not found");
      } else {
        setResponse("Error");
      }
    } catch (error) {
      console.error(error);
      setResponse("Error");
    }
  };

  return (
    <div className="App">
      <h1>Add Words</h1>
      <input
        type="text"
        value={word}
        onChange={(e) => setWord(e.target.value)}
      />
      <button onClick={handleAddWord}>Add</button>
      <ul>
        {words.map((word, index) => (
          <li key={index}>{word}</li>
        ))}
      </ul>
      <button onClick={handleAddToDB}>Send to DB</button>
      {responseAdd && <p>{responseAdd}</p>}

      <h1>Find Word</h1>
      <input
        type="text"
        value={word}
        onChange={(e) => setWord(e.target.value)}
      />
      <button onClick={handleFindWord}>Find</button>
      {response && <p>{response}</p>}
    </div>
  );
}

export default App;
