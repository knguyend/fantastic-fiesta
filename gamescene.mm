#include "gamescene.h"
#include <memory>
#include <QDebug>
#define ELEMENTSIZE 60
#define SQUARE 60
#define DISTANCE ELEMENTSIZE*2

GameScene::GameScene(QLabel * moveInfoLabel)
{
    this->moveInfo = moveInfoLabel;
    this->whitePlayerMove = true;
    this->isPawnSelected = false;
    this->isDuringMove = false;
    this->blackBrush= QBrush(Qt::black);
    this->darkBrownBrush = QBrush("#eee2ca");
    this->lightBrownBrush = QBrush("#83652c");
    this->whiteKingBrush = QBrush(Qt::lightGray);
    this->blackKingBrush = QBrush(Qt::blue);
    this->outlinePen4Chessboard = QPen(Qt::black);
    this->outlinePen4Pawn = QPen(Qt::black);
    this->outlinePen4SelectedPawn = QPen(Qt::yellow);
    this->whiteBrush = QBrush(Qt::white);
    this->outlinePen4Chessboard.setWidth(1);
    this->outlinePen4Pawn.setWidth(1);
    SetChessboard(this);
    SetPawns(this);
    //Moves(itemAt(this->scenePos(), QTransform::fromScale(1, 1)),60,60);
}

//Draw a pawn
Pawn * GameScene::PawnMaker(int x, int y, QGraphicsScene * scene, QPen pen, QBrush brush)
{
    Pawn * result = new Pawn();
    result->pawn = scene->addEllipse(0, 0, ELEMENTSIZE, ELEMENTSIZE, pen, brush);
    result->pawn->setPos(x * ELEMENTSIZE, y * ELEMENTSIZE);
    return result;
}

//Draw a square
QGraphicsRectItem * GameScene::FieldMaker(int x, int y, QGraphicsScene * scene, QPen pen, QBrush brush )
{
    QGraphicsRectItem * result = new QGraphicsRectItem();
    result = scene->addRect(0, 0, SQUARE, SQUARE, pen, brush);
    result->setPos(x* SQUARE, y * SQUARE);
    return result;
}

//Draw the chessboard
void GameScene::SetChessboard(QGraphicsScene* scene)
{
    bool nowWhite = true;
    for  (int y = 0 ; y < 8 ; y++)
    {
        for (int x = 0 ; x < 8 ; x++)
        {
            if (nowWhite) {
                whiteFieldsList.push_back(FieldMaker(x, y, scene, this->outlinePen4Chessboard, this->lightBrownBrush));
            }
            else {
                blackFieldsList.push_back(FieldMaker(x, y, scene, this->outlinePen4Chessboard, this->darkBrownBrush));
            }
            nowWhite = !nowWhite;
        }
        nowWhite = !nowWhite;
    }
}

//Draw all pawns
void GameScene::SetPawns(QGraphicsScene* scene)
{
    bool skip = true;
    for(int y = 0 ; y < 3 ; y++)
    {
        if(skip)
        {
            for(int x = 1 ; x < 8 ; x+=2) {
                blackPawnsList.push_back(PawnMaker(x, y, scene, this->outlinePen4Pawn, this->blackBrush));
            }
            skip = false;
        }
        else
        {
            for(int x = 0 ; x < 8 ; x+=2) {
                blackPawnsList.push_back(PawnMaker(x, y, scene, this->outlinePen4Pawn, this->blackBrush));
            }
            skip = true;
        }
    }
    skip = true;
    for(int y = 5 ; y < 8 ; y++)
    {
        if(skip)
        {
            for(int x = 0 ; x < 8 ; x+=2) {
                whitePawnsList.push_back(PawnMaker(x, y, scene, this->outlinePen4Pawn, this->whiteBrush));
            }
            skip = false;
        }
        else
        {
            for(int x = 1 ; x < 8 ; x+=2) {
                whitePawnsList.push_back(PawnMaker(x, y, scene, this->outlinePen4Pawn, this->whiteBrush));
            }
            skip = true;
        }
    }
}


//What happens when mouseclick
void GameScene::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    QGraphicsRectItem rectType;
    QGraphicsEllipseItem ellipseType;
    QGraphicsItem *item = itemAt(event->scenePos(), QTransform::fromScale(1, 1));
    if (this->currentlySelectedPawn == NULL){
        if ( item->type() == ellipseType.type() && this->isDuringMove == false ) {
            //White player
            if (this->whitePlayerMove){
                for (int i = 0 ; i < whitePawnsList.size() ; ++i) {
                    if ( item->pos() == whitePawnsList.at(i)->pawn->pos() && this->whitePlayerMove ) {
                        this->currentlySelectedPawn = whitePawnsList.at(i)->pawn;
                        this->currentlySelectedPawn->setPen(this->outlinePen4SelectedPawn);
                        this->isDuringMove = true;
                        return;
                    }
                }
            }
            //Black player
            else {
                for (int i = 0 ; i < blackPawnsList.size() ; ++i) {
                    if ( item->pos() == blackPawnsList.at(i)->pawn->pos()) {
                        this->currentlySelectedPawn = blackPawnsList.at(i)->pawn;
                        this->currentlySelectedPawn->setPen(this->outlinePen4SelectedPawn);
                        this -> isDuringMove = true;
                        return;
                        }
                    }
                }
            }
        }
    //Pawn is selected
    else if (itemIsKing(event)) {
        if (checkMoveKing(event)) {
            move(event);
            return;
        }
        else if (checkJumpKing(event) != NULL){
            Pawn* eaten = checkJumpKing(event);
            jump(event);
            removeItem(eaten->pawn);
            return;
        }
    }
    else {
        if (checkMove(event)){
            move(event);
            return;
        }
        //Jump
        else if (checkJump(event) != NULL){
            Pawn* eaten = checkJump(event);
            jump(event);
            removeItem(eaten->pawn);
            return;
        }
        else {
            ResetPawn();
            return;
        }
    }

}

//Deselect pawn
void GameScene::ResetPawn()
{
    CheckIfKing();
    this->currentlySelectedPawn->setPen(this->outlinePen4Pawn);
    this->isPawnSelected = false;
    this->currentlySelectedPawn = NULL;
    this->isDuringMove = false;
}

void GameScene::CheckIfKing()
{
        for(int i = 0 ; i < whitePawnsList.size() ; ++i)
        {
            if(this->currentlySelectedPawn->scenePos().y() == 0
               && this->currentlySelectedPawn->scenePos() == whitePawnsList.at(i)->pawn->scenePos())
            {
                if (this->whitePawnsList.at(i)->isKing) { return; }
                this->whitePawnsList.at(i)->isKing = true;
                this->whitePawnsList.at(i)->pawn->setBrush(this->whiteKingBrush);
            }
        }
        for(int i = 0 ; i < blackPawnsList.size() ; ++i)
        {
            if(this->currentlySelectedPawn->scenePos().y() == 7*ELEMENTSIZE
               && this->currentlySelectedPawn->scenePos() == blackPawnsList.at(i)->pawn->scenePos())
            {
                if (this->blackPawnsList.at(i)->isKing) { return; }
                this->blackPawnsList.at(i)->isKing = true;
                this->blackPawnsList.at(i)->pawn->setBrush(this->blackKingBrush);
            }
        }
}

//Check for legitmate move
bool GameScene::checkMove(QGraphicsSceneMouseEvent *event){
    QGraphicsItem *item = itemAt(event->scenePos(), QTransform::fromScale(1, 1));
    QGraphicsRectItem rectType;
    QGraphicsEllipseItem ellipseType;
    //Not a field
    if (item->type() != rectType.type())
            return false;
    else {
        //There's a pawn in the field
        /*for (int i = 0 ; i < blackPawnsList.size() ; i++) {
            if ( ((blackPawnsList.at(i)->pawn->x() == item->x())
                 && (blackPawnsList.at(i)->pawn->y() == item->y()))
                 || ((whitePawnsList.at(i)->pawn->x() == item->x())
                 && (whitePawnsList.at(i)->pawn->y() == item->y())))
                return false;*/

    }
    if (this->whitePlayerMove) {
        //If it's a valid nearbyfield
        if (((item->x() - this->currentlySelectedPawn->x() == ELEMENTSIZE)
             || (item->x() - this->currentlySelectedPawn->x() == -ELEMENTSIZE))
                && (this->currentlySelectedPawn->y() - item->y()  == ELEMENTSIZE))
            return true;
    }
    //For black pawns
    else {
        //Valid nearby field
        if ( ((item->x() - this->currentlySelectedPawn->x() == ELEMENTSIZE)
             || (item->x() - this->currentlySelectedPawn->x() == -ELEMENTSIZE))
                && (item->y() - this->currentlySelectedPawn->y()  == ELEMENTSIZE))
            return true;
    }
    return false;
}

bool GameScene::checkMoveKing(QGraphicsSceneMouseEvent *event) {
    QGraphicsItem *item = itemAt(event->scenePos(), QTransform::fromScale(1, 1));
    QGraphicsRectItem rectType;
    QGraphicsEllipseItem ellipseType;
    //Normal move
    if (checkMove(event))
        return true;
    //Move backwards
    if (this->whitePlayerMove) {
        //If it's a valid nearbyfield
        if (((item->x() - this->currentlySelectedPawn->x() == ELEMENTSIZE)
             || (item->x() - this->currentlySelectedPawn->x() == -ELEMENTSIZE))
                && (this->currentlySelectedPawn->y() - item->y()  == -ELEMENTSIZE))
            return true;
    }
    //For black pawns
    else {
        //Valid nearby field
        if ( ((item->x() - this->currentlySelectedPawn->x() == ELEMENTSIZE)
             || (item->x() - this->currentlySelectedPawn->x() == -ELEMENTSIZE))
                && (item->y() - this->currentlySelectedPawn->y()  == -ELEMENTSIZE))
            return true;
    }
    return false;

}

Pawn* GameScene::checkJump(QGraphicsSceneMouseEvent *event){
    QGraphicsItem *item = itemAt(event->scenePos(), QTransform::fromScale(1, 1));
    QGraphicsRectItem rectType;
    QGraphicsEllipseItem ellipseType;
    if (item->type() != rectType.type())
            return NULL;
    if(this->whitePlayerMove){
    //There's a black pawn up & right
        if  ((item->x() - this->currentlySelectedPawn->x() == DISTANCE)
                  && (this->currentlySelectedPawn->y() - item->y()  == DISTANCE)){
            for (int i = 0 ; i < blackPawnsList.size() ; i++) {
                if ( (blackPawnsList.at(i)->pawn->x() == this->currentlySelectedPawn->x()+ELEMENTSIZE)
                     && (blackPawnsList.at(i)->pawn->y() == this->currentlySelectedPawn->y()-ELEMENTSIZE))
                    return blackPawnsList.at(i);
            }
        }
        else if ((item->x() - this->currentlySelectedPawn->x() == -DISTANCE)
                 && (this->currentlySelectedPawn->y() - item->y()  == DISTANCE)){
           for (int i = 0 ; i < blackPawnsList.size() ; i++) {
               if ( (blackPawnsList.at(i)->pawn->x() == this->currentlySelectedPawn->x()-ELEMENTSIZE)
                    && (blackPawnsList.at(i)->pawn->y() == this->currentlySelectedPawn->y()-ELEMENTSIZE))
                   return blackPawnsList.at(i);
           }
        }
    }
    //Black's turn
    else {
        //There's a white pawn down & right
        if  ((item->x() - this->currentlySelectedPawn->x() == DISTANCE)
                  && (this->currentlySelectedPawn->y() - item->y()  == -DISTANCE)){
            for (int j = 0 ; j < whitePawnsList.size() ; j++) {
                if ( (whitePawnsList.at(j)->pawn->x() == this->currentlySelectedPawn->x()+ELEMENTSIZE)
                     && (whitePawnsList.at(j)->pawn->y() == this->currentlySelectedPawn->y()+ELEMENTSIZE))
                    return whitePawnsList.at(j);
            }
        }
        //There's a white pawn down & left
        else if ((item->x() - this->currentlySelectedPawn->x() == -DISTANCE)
                 && (this->currentlySelectedPawn->y() - item->y()  == -DISTANCE)) {
           for (int j = 0 ; j < whitePawnsList.size() ; j++) {
               if ( whitePawnsList.at(j)->pawn->x() == this->currentlySelectedPawn->x()-ELEMENTSIZE
                    && whitePawnsList.at(j)->pawn->y() == this->currentlySelectedPawn->y()+ELEMENTSIZE)
                   return whitePawnsList.at(j);
           }
       }
    }
    return NULL;
}

//Check valid jump for kings
Pawn* GameScene::checkJumpKing(QGraphicsSceneMouseEvent *event){
    QGraphicsItem *item = itemAt(event->scenePos(), QTransform::fromScale(1, 1));
    QGraphicsRectItem rectType;
    QGraphicsEllipseItem ellipseType;
    if (checkJump(event) == NULL)
            return NULL;
    if(this->whitePlayerMove){
    //There's a black pawn up & right
        if  ((item->x() - this->currentlySelectedPawn->x() == DISTANCE)
                  && (this->currentlySelectedPawn->y() - item->y()  == -DISTANCE)){
            for (int i = 0 ; i < blackPawnsList.size() ; i++) {
                if ( (blackPawnsList.at(i)->pawn->x() == this->currentlySelectedPawn->x()+ELEMENTSIZE)
                     && (blackPawnsList.at(i)->pawn->y() == this->currentlySelectedPawn->y()-ELEMENTSIZE))
                    return blackPawnsList.at(i);
            }
        }
        else if ((item->x() - this->currentlySelectedPawn->x() == -DISTANCE)
                 && (this->currentlySelectedPawn->y() - item->y()  == -DISTANCE)){
           for (int i = 0 ; i < blackPawnsList.size() ; i++) {
               if ( (blackPawnsList.at(i)->pawn->x() == this->currentlySelectedPawn->x()-ELEMENTSIZE)
                    && (blackPawnsList.at(i)->pawn->y() == this->currentlySelectedPawn->y()-ELEMENTSIZE))
                   return blackPawnsList.at(i);
           }
        }
    }
    //Black's turn
    else {
        //There's a white pawn down & right
        if  ((item->x() - this->currentlySelectedPawn->x() == DISTANCE)
                  && (this->currentlySelectedPawn->y() - item->y()  == DISTANCE)){
            for (int j = 0 ; j < whitePawnsList.size() ; j++) {
                if ( (whitePawnsList.at(j)->pawn->x() == this->currentlySelectedPawn->x()+ELEMENTSIZE)
                     && (whitePawnsList.at(j)->pawn->y() == this->currentlySelectedPawn->y()+ELEMENTSIZE))
                    return whitePawnsList.at(j);
            }
        }
        //There's a white pawn down & left
        else if ((item->x() - this->currentlySelectedPawn->x() == -DISTANCE)
                 && (this->currentlySelectedPawn->y() - item->y()  == DISTANCE)) {
           for (int j = 0 ; j < whitePawnsList.size() ; j++) {
               if ( whitePawnsList.at(j)->pawn->x() == this->currentlySelectedPawn->x()-ELEMENTSIZE
                    && whitePawnsList.at(j)->pawn->y() == this->currentlySelectedPawn->y()+ELEMENTSIZE)
                   return whitePawnsList.at(j);
           }
       }
    }
    return NULL;
}


void GameScene::move(QGraphicsSceneMouseEvent *event){
    QGraphicsItem *item = itemAt(event->scenePos(), QTransform::fromScale(1, 1));
        this->currentlySelectedPawn->setPos(item->x(),item->y());
        ResetPawn();
        this->whitePlayerMove = !this->whitePlayerMove;
        return;
}

void GameScene::jump(QGraphicsSceneMouseEvent *event){
    QGraphicsItem *item = itemAt(event->scenePos(), QTransform::fromScale(1, 1));
        this->currentlySelectedPawn->setPos(item->x(),item->y());
        ResetPawn();
        this->whitePlayerMove = !this->whitePlayerMove;
        return;
}

//Check if it's King
bool GameScene::itemIsKing(QGraphicsSceneMouseEvent *event){
    QGraphicsItem *item = itemAt(event->scenePos(), QTransform::fromScale(1, 1));
    if(this->whitePlayerMove){
        for (int i = 0 ; i < blackPawnsList.size() ; i++) {
            if (blackPawnsList.at(i)->isKing){
                if ( ((blackPawnsList.at(i)->pawn->x() == item->x())
                    && (blackPawnsList.at(i)->pawn->y() == item->y())))
                    return true;
            }
        }
    }
        //Black's turn
     else {
        for (int i = 0 ; i < whitePawnsList.size() ; i++) {
            if (whitePawnsList.at(i)->isKing){
                if ( ((whitePawnsList.at(i)->pawn->x() == item->x())
                    && (whitePawnsList.at(i)->pawn->y() == item->y())))
                    return true;
            }
        }
    }
    return false;
}