async function loadFile(filename) {
    let url = `/file/${filename}`;
    let resp = await fetch(url);
    if (!resp.ok) {
        throw new Error(`File loading error: ${resp.status}`)
    }
    const data = await resp.text();
    const codeTxt = document.getElementById("code-txt")
    codeTxt.textContent = data;
}

function populateListOfFiles(data) {
    const fileList = document.getElementById("file-lst");
    for (const filename of data) {
        const li = document.createElement("li");
        li.className = "list-group-item"
        li.textContent = filename;
        li.addEventListener("click", (evt) => {
            loadFile(filename)
        });
        fileList.appendChild(li);
    }
}

async function updateFileList() {
    let resp = await fetch("/list")
    if (!resp.ok) {
        throw new Error(`http error: ${resp.status}`);
    }
    const data = await resp.json();
    populateListOfFiles(data);
}

async function executeCode() {
    const codeTxt = document.getElementById("code-txt")
    console.log(codeTxt.textContent);
    const resp = await fetch("/execute", {
        method: "POST",
        headers: {
            "Content-type": "text/plain",
        },
        body: codeTxt.textContent,
    })
    if (!resp.ok) {
        throw new Error(`Execution failed: ${resp.status}`)
    }
    const output = await resp.text();
    const outputTxt = document.getElementById("output-txt");
    outputTxt.textContent = output;
}

document.getElementById("clear-btn")
    .addEventListener("click", (evt) => {
        const codeTxt = document.getElementById("code-txt")
        const outputTxt = document.getElementById("output-txt")
        codeTxt.textContent = "";
        outputTxt.textContent = "";
    })

document.getElementById("run-btn")
    .addEventListener("click", (evt) => {
        executeCode();
    });

updateFileList();
